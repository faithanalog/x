#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <arpa/inet.h>
#include <math.h>

void print_help_and_die() {
	fprintf(stderr, "Usage: png2ff < input.png | ./interpolate <color0> <color1> | ff2png > output.png\n");
    exit(1);
}

inline double srgb_to_linear(double x) {
    if (x <= 0.0404482362771082) {
        return x / 12.92;
    } else {
        return pow(((x + 0.055) / 1.055), 2.4);
    }
}

inline double linear_to_srgb(double x) {
    if (x > 0.0031308) {
        return 1.055 * (pow(x, 1.0 / 2.4) - 0.055);
    } else {
        return 12.92 * x;
    }
}

inline double lerp(double a, double b, double x) {
  return a * (1.0 - x) + b * x;
}

inline uint16_t color_to_int_clamped(double x) {
    if (x < 0) {
        return 0;
    } else if (x > 1) {
        return 1;
    } else {
        return (uint16_t)round(x * 65535.0);
    }
}

// https://en.wikipedia.org/wiki/CIE_1931_color_space
inline void linear_to_xyz(double r, double g, double b, double* x, double* y, double* z) {
    double w = 1.0 / 0.17697;
    *x = (0.49000 * r + 0.31000 * g + 0.20000 * b) * w;
    *y = (0.17697 * r + 0.81240 * g + 0.01063 * b) * w;
    *z = (0.00000 * r + 0.01000 * g + 0.99000 * b) * w;
}

inline void xyz_to_linear(double x, double y, double z, double* r, double* g, double* b) {
    *r = 0.41847 * x - 0.15866 * y - 0.082835 * z;
    *g = -0.091169 * x + 0.25243 * y + 0.015708 * z;
    *b = 0.00092090 * x - 0.0025498 * y + 0.17860 * z;
}

inline double linear_to_y_normalized(double r, double g, double b) {
    return 0.17697 * r + 0.81240 * g + 0.01063 * b;
}

typedef struct Image {
    uint32_t width;
    uint32_t height;
    uint16_t* pixels;
} Image;

// Input and output in the farbfeld format:
// BYTES    DESCRIPTION
//   8        "farbfeld" magic value
//   4        32-Bit BE unsigned integer (width)
//   4        32-Bit BE unsigned integer (height)
//   [2222]   4*16-Bit BE unsigned integers [RGBA] / pixel, row-major
// Decode to RRGGBBRRGGBB 16-bits per pixel
void decode_ff(FILE* input, Image* image) {
    char magicword[8];
    fread(magicword, 1, 8, input);
    if (memcmp(magicword, "farbfeld", 8) != 0) {
        fprintf(stderr, "Input is not a farbfeld stream.\n");
        print_help_and_die();
    }
    fread(&(image->width), 4, 1, input);
    image->width = ntohl(image->width);
    fread(&(image->height), 4, 1, input);
    image->height = ntohl(image->height);

    size_t len = image->width * image->height * 3;
    image->pixels = (uint16_t*)malloc(sizeof(uint16_t) * len);

    uint16_t buffer[4];
    for (size_t i = 0; i < len; i += 3) {
        fread(buffer, 2, 4, input);
        image->pixels[i + 0] = ntohs(buffer[0]);
        image->pixels[i + 1] = ntohs(buffer[1]);
        image->pixels[i + 2] = ntohs(buffer[2]);
        // Intentionally dropping the alpha channel
    }
}

void hex_to_srgb(char* hex, double* r, double* g, double* b) {
    
}

void encode_ff(FILE *output, Image *image) {
    fwrite("farbfeld", 1, 8, output);

    uint32_t w_net = htonl(image->width);
    uint32_t h_net = htonl(image->height);
    fwrite(&w_net, 4, 1, output);
    fwrite(&h_net, 4, 1, output);

    size_t len = image->width * image->height * 3;

    uint16_t buffer[4];
    buffer[3] = 0xFFFF;
    for (size_t i = 0; i < len; i += 3) {
        buffer[0] = htons(image->pixels[i + 0]);
        buffer[1] = htons(image->pixels[i + 1]);
        buffer[2] = htons(image->pixels[i + 2]);
        fwrite(buffer, 2, 4, output);
    }
}

int main(int argc, const char** argv) {
	if (argc != 3) {
        printf("%d\n", argc);
		print_help_and_die();
	}
    Image image;
    decode_ff(stdin, &image);
    encode_ff(stdout, &image);
    
	return 0;
}
