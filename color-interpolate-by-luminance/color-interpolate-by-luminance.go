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

func print_help_and_die() {
	fmt.Fprintf(os.Stderr, "Usage: 2ff < input.whatever | ./color-interpolate-by-luminance <color0> <color1> | ff2png > output.png\n")
	os.Exit(1)
}

type Color_SRGB struct {
	r float64
	g float64
	b float64
}

type Color_LRGB struct {
	r float64
	g float64
	b float64
}

type Color_XYZ struct {
	x float64
	y float64
	z float64
}

func srgb_to_linear_d(x float64) float64 {
	if x <= 0.0404482362771082 {
		return x / 12.92
	} else {
		return math.Pow(((x + 0.055) / 1.055), 2.4)
	}
}

func linear_to_srgb_d(x float64) float64 {
	if x > 0.0031308 {
		return 1.055 * (math.Pow(x, 1.0/2.4) - 0.055)
	} else {
		return 12.92 * x
	}
}

func srgb_to_linear(i Color_SRGB) Color_LRGB {
	return Color_LRGB{
		r: srgb_to_linear_d(i.r),
		g: srgb_to_linear_d(i.g),
		b: srgb_to_linear_d(i.b),
	}
}

func linear_to_srgb(i Color_LRGB) Color_SRGB {
	return Color_SRGB{
		r: linear_to_srgb_d(i.r),
		g: linear_to_srgb_d(i.g),
		b: linear_to_srgb_d(i.b),
	}
}

func lerp(a, b, x float64) float64 {
	return a*(1.0-x) + b*x
}

func color_to_int_clamped(x float64) uint16 {
	if x < 0 {
		return 0
	} else if x > 1 {
		return 1
	} else {
		return uint16(math.Round(x * 65535.0))
	}
}

// https://en.wikipedia.org/wiki/CIE_1931_color_space
func linear_to_xyz(i Color_LRGB) Color_XYZ {
	w := 1.0 / 0.17697
	return Color_XYZ{
		x: (0.49000*i.r + 0.31000*i.g + 0.20000*i.b) * w,
		y: (0.17697*i.r + 0.81240*i.g + 0.01063*i.b) * w,
		z: (0.00000*i.r + 0.01000*i.g + 0.99000*i.b) * w,
	}
}

func xyz_to_linear(i Color_XYZ) Color_LRGB {
	return Color_LRGB{
		r: 0.41847*i.x - 0.15866*i.y - 0.082835*i.z,
		g: -0.091169*i.x + 0.25243*i.y + 0.015708*i.z,
		b: 0.00092090*i.x - 0.0025498*i.y + 0.17860*i.z,
	}
}

func linear_to_y_normalized(i Color_LRGB) float64 {
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
func decode_ff(input io.Reader) Image {
	magicword := make([]byte, 8)
	input.Read(magicword)
	if string(magicword) != "farbfeld" {
		fmt.Fprintf(os.Stderr, "Input is not a farbfeld stream.\n")
		print_help_and_die()
	}

	image := Image{}

	binary.Read(input, binary.BigEndian, &image.width)
	binary.Read(input, binary.BigEndian, &image.height)

	length := image.width * image.height * 4
	image.pixels = make([]uint16, length)

	binary.Read(input, binary.BigEndian, image.pixels)

	return image
}

func encode_ff(output io.Writer, image Image) {
	output.Write([]byte("farbfeld"))
	binary.Write(output, binary.BigEndian, image.width)
	binary.Write(output, binary.BigEndian, image.height)
	binary.Write(output, binary.BigEndian, image.pixels)
}

func hex_to_srgb(hex string) Color_SRGB {
	if hex[0] != '#' || len(hex) != 7 {
		fmt.Fprintf(os.Stderr, "Invalid color %s\n", hex)
		print_help_and_die()
	}
	for _, c := range hex[1:7] {
		if !(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f') && !(c >= 'A' && c <= 'F') {
			fmt.Fprintf(os.Stderr, "Invalid color %s\n", hex)
			print_help_and_die()
		}
	}
	color, _ := strconv.ParseInt(hex[1:7], 16, 64)
	return Color_SRGB{
		r: float64((color>>16)&0xFF) / 255.0,
		g: float64((color>>8)&0xFF) / 255.0,
		b: float64((color>>0)&0xFF) / 255.0,
	}
}

func main() {
	if len(os.Args) != 3 {
		print_help_and_die()
	}

	dark_srgb := hex_to_srgb(os.Args[1])
	light_srgb := hex_to_srgb(os.Args[2])
	dark := linear_to_xyz(srgb_to_linear(dark_srgb))
	light := linear_to_xyz(srgb_to_linear(light_srgb))

	image := decode_ff(os.Stdin)
	w := int(image.width)
	h := int(image.height)

	waitgroup := sync.WaitGroup{}
	waitgroup.Add(h)

	palettize_row := func(y int) {
		start := y * w * 4
		end := start + w*4
		for i := start; i < end; i += 4 {
			in_srgb := Color_SRGB{
				r: float64(image.pixels[i+0]) / 65535.0,
				g: float64(image.pixels[i+1]) / 65535.0,
				b: float64(image.pixels[i+2]) / 65535.0,
			}

			sf := linear_to_y_normalized(srgb_to_linear(in_srgb))

			xyz := Color_XYZ{
				x: lerp(dark.x, light.x, sf),
				y: lerp(dark.y, light.y, sf),
				z: lerp(dark.z, light.z, sf),
			}

			out_srgb := linear_to_srgb(xyz_to_linear(xyz))

			image.pixels[i+0] = color_to_int_clamped(out_srgb.r)
			image.pixels[i+1] = color_to_int_clamped(out_srgb.g)
			image.pixels[i+2] = color_to_int_clamped(out_srgb.b)
		}
		waitgroup.Done()
	}

	for y := 0; y < h; y++ {
		go palettize_row(y)
	}

	waitgroup.Wait()

	encode_ff(os.Stdout, image)
}
