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

typedef struct Color_SRGB {
    double r;
    double g;
    double b;
} Color_SRGB;

typedef struct Color_LRGB {
    double r;
    double g;
    double b;
} Color_LRGB;

typedef struct Color_XYZ {
    double x;
    double y;
    double z;
} Color_XYZ;

inline double srgb_to_linear_d(double x) {
    if (x <= 0.0404482362771082) {
        return x / 12.92;
    } else {
        return pow(((x + 0.055) / 1.055), 2.4);
    }
}

inline double linear_to_srgb_d(double x) {
    if (x > 0.0031308) {
        return 1.055 * (pow(x, 1.0 / 2.4) - 0.055);
    } else {
        return 12.92 * x;
    }
}

inline Color_LRGB srgb_to_linear(Color_SRGB i) {
    Color_LRGB o = {
        .r = srgb_to_linear_d(i.r),
        .g = srgb_to_linear_d(i.g),
        .b = srgb_to_linear_d(i.b)
    };
    return o;
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
inline Color_XYZ linear_to_xyz(Color_LRGB i) {
    double w = 1.0 / 0.17697;
    Color_XYZ o = {
        .x = (0.49000 * i.r + 0.31000 * i.g + 0.20000 * i.b) * w,
        .y = (0.17697 * i.r + 0.81240 * i.g + 0.01063 * i.b) * w,
        .z = (0.00000 * i.r + 0.01000 * i.g + 0.99000 * i.b) * w
    };
    return o;
}

inline Color_LRGB xyz_to_linear(Color_XYZ i) {
    Color_LRGB o = {
        .r = 0.41847 * i.x - 0.15866 * i.y - 0.082835 * i.z,
        .g = -0.091169 * i.x + 0.25243 * i.y + 0.015708 * i.z,
        .b = 0.00092090 * i.x - 0.0025498 * i.y + 0.17860 * i.z
    };
    return o;
}

inline double linear_to_y_normalized(Color_LRGB i) {
    return 0.17697 * i.r + 0.81240 * i.g + 0.01063 * i.b;
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
// Decode to RRGGBBAARRGGBBAA 16-bits per pixel
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

    size_t len = image->width * image->height * 4;
    image->pixels = (uint16_t*)malloc(sizeof(uint16_t) * len);
    fread(image->pixels, 2, len, input);

    for (size_t i = 0; i < len; i += 4) {
        image->pixels[i + 0] = ntohs(image->pixels[i + 0]);
        image->pixels[i + 1] = ntohs(image->pixels[i + 1]);
        image->pixels[i + 2] = ntohs(image->pixels[i + 2]);
        image->pixels[i + 3] = ntohs(image->pixels[i + 3]);
    }
}

void hex_to_srgb(char* hex, double* r, double* g, double* b) {
    if (*hex != '#' || strlen(hex) != 7) {
        printf("Invalid color %s\n", hex);
        print_help_and_die();
    }
    for (size_t i = 1; i < 7; i++) {
        char c = hex[i];
        // This will catch null terminators too so we're good there.
        if (!(c >= '0' && c <= '9') && !(c >= 'a' && c <= 'f') && !(c >= 'A' && c <= 'F')) {
            printf("Invalid color %s\n", hex);
            print_help_and_die();
        }
    }
    long int color = strtol(hex + 1, NULL, 16);
    *r = (double)((color >> 16) & 0xFF) / 255.0;
    *g = (double)((color >>  8) & 0xFF) / 255.0;
    *b = (double)((color >>  0) & 0xFF) / 255.0;
}

void encode_ff(FILE *output, Image *image) {
    fwrite("farbfeld", 1, 8, output);

    uint32_t w_net = htonl(image->width);
    uint32_t h_net = htonl(image->height);
    fwrite(&w_net, 4, 1, output);
    fwrite(&h_net, 4, 1, output);

    size_t len = image->width * image->height * 4;
    uint16_t* buffer = (uint16_t*)malloc(sizeof(uint16_t) * len);
    for (size_t i = 0; i < len; i += 4) {
        buffer[i + 0] = htons(image->pixels[i + 0]);
        buffer[i + 1] = htons(image->pixels[i + 1]);
        buffer[i + 2] = htons(image->pixels[i + 2]);
        buffer[i + 3] = htons(image->pixels[i + 3]);
    }
    fwrite(buffer, 2, len, output);
    free(buffer);
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
