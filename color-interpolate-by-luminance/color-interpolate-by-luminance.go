package main

import (
	"encoding/binary"
	"fmt"
	"io"
	"math"
	"os"
	"strconv"
	"sync"
)

func printHelpAndDie() {
	fmt.Fprintf(os.Stderr, "Usage: 2ff < input.whatever | ./color-interpolate-by-luminance <color0> <color1> | ff2png > output.png\n")
	os.Exit(1)
}

type colorSRGB struct {
	r float64
	g float64
	b float64
}

type colorLRGB struct {
	r float64
	g float64
	b float64
}

type colorXYZ struct {
	x float64
	y float64
	z float64
}

func srgbToLinearD(x float64) float64 {
	if x <= 0.0404482362771082 {
		return x / 12.92
	} else {
		return math.Pow(((x + 0.055) / 1.055), 2.4)
	}
}

func linearToSRGBD(x float64) float64 {
	if x > 0.0031308 {
		return 1.055 * (math.Pow(x, 1.0/2.4) - 0.055)
	} else {
		return 12.92 * x
	}
}

func srgbToLinear(i colorSRGB) colorLRGB {
	return colorLRGB{
		r: srgbToLinearD(i.r),
		g: srgbToLinearD(i.g),
		b: srgbToLinearD(i.b),
	}
}

func linearToSRGB(i colorLRGB) colorSRGB {
	return colorSRGB{
		r: linearToSRGBD(i.r),
		g: linearToSRGBD(i.g),
		b: linearToSRGBD(i.b),
	}
}

func lerp(a, b, x float64) float64 {
	return a*(1.0-x) + b*x
}

func colorToIntClamped(x float64) uint16 {
	if x < 0 {
		return 0
	} else if x > 1 {
		return 1
	} else {
		return uint16(math.Round(x * 65535.0))
	}
}

// https://en.wikipedia.org/wiki/CIE_1931ColorSpace
func linearToXYZ(i colorLRGB) colorXYZ {
	w := 1.0 / 0.17697
	return colorXYZ{
		x: (0.49000*i.r + 0.31000*i.g + 0.20000*i.b) * w,
		y: (0.17697*i.r + 0.81240*i.g + 0.01063*i.b) * w,
		z: (0.00000*i.r + 0.01000*i.g + 0.99000*i.b) * w,
	}
}

func xyzToLinear(i colorXYZ) colorLRGB {
	return colorLRGB{
		r: 0.41847*i.x - 0.15866*i.y - 0.082835*i.z,
		g: -0.091169*i.x + 0.25243*i.y + 0.015708*i.z,
		b: 0.00092090*i.x - 0.0025498*i.y + 0.17860*i.z,
	}
}

func linearToYNormalized(i colorLRGB) float64 {
	return 0.17697*i.r + 0.81240*i.g + 0.01063*i.b
}

type Image struct {
	width  uint32
	height uint32
	pixels []uint16
}

// Input and output in the farbfeld format:
// BYTES    DESCRIPTION
//   8        "farbfeld" magic value
//   4        32-Bit BE unsigned integer (width)
//   4        32-Bit BE unsigned integer (height)
//   [2222]   4*16-Bit BE unsigned integers [RGBA] / pixel, row-major
// Decode to RRGGBBAARRGGBBAA 16-bits per pixel
func decodeFarbfeld(input io.Reader) Image {
	magicWord := make([]byte, 8)
	input.Read(magicWord)
	if string(magicWord) != "farbfeld" {
		fmt.Fprintf(os.Stderr, "Input is not a farbfeld stream.\n")
		printHelpAndDie()
	}

	image := Image{}

	binary.Read(input, binary.BigEndian, &image.width)
	binary.Read(input, binary.BigEndian, &image.height)

	length := image.width * image.height * 4
	image.pixels = make([]uint16, length)

	binary.Read(input, binary.BigEndian, image.pixels)

	return image
}

func encodeFarbfeld(output io.Writer, image Image) {
	output.Write([]byte("farbfeld"))
	binary.Write(output, binary.BigEndian, image.width)
	binary.Write(output, binary.BigEndian, image.height)
	binary.Write(output, binary.BigEndian, image.pixels)
}

func hexToSRGB(hex string) colorSRGB {
	if hex[0] != '#' || len(hex) != 7 {
		fmt.Fprintf(os.Stderr, "Invalid color %s\n", hex)
		printHelpAndDie()
	}
	for _, c := range hex[1:7] {
		if !(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f') && !(c >= 'A' && c <= 'F') {
			fmt.Fprintf(os.Stderr, "Invalid color %s\n", hex)
			printHelpAndDie()
		}
	}
	color, _ := strconv.ParseInt(hex[1:7], 16, 64)
	return colorSRGB{
		r: float64((color>>16)&0xFF) / 255.0,
		g: float64((color>>8)&0xFF) / 255.0,
		b: float64((color>>0)&0xFF) / 255.0,
	}
}

func main() {
	if len(os.Args) != 3 {
		printHelpAndDie()
	}

	darkSRGB := hexToSRGB(os.Args[1])
	lightSRGB := hexToSRGB(os.Args[2])
	dark := linearToXYZ(srgbToLinear(darkSRGB))
	light := linearToXYZ(srgbToLinear(lightSRGB))

	image := decodeFarbfeld(os.Stdin)
	w := int(image.width)
	h := int(image.height)

	waitGroup := sync.WaitGroup{}
	waitGroup.Add(h)

	palettizeRow := func(y int) {
		start := y * w * 4
		end := start + (w * 4)
		for i := start; i < end; i += 4 {
			inSRGB := colorSRGB{
				r: float64(image.pixels[i+0]) / 65535.0,
				g: float64(image.pixels[i+1]) / 65535.0,
				b: float64(image.pixels[i+2]) / 65535.0,
			}

			sf := linearToYNormalized(srgbToLinear(inSRGB))

			xyz := colorXYZ{
				x: lerp(dark.x, light.x, sf),
				y: lerp(dark.y, light.y, sf),
				z: lerp(dark.z, light.z, sf),
			}

			outSRGB := linearToSRGB(xyzToLinear(xyz))

			image.pixels[i+0] = colorToIntClamped(outSRGB.r)
			image.pixels[i+1] = colorToIntClamped(outSRGB.g)
			image.pixels[i+2] = colorToIntClamped(outSRGB.b)
		}
		waitGroup.Done()
	}

	for y := 0; y < h; y++ {
		go palettizeRow(y)
	}

	waitGroup.Wait()

	encodeFarbfeld(os.Stdout, image)
}
