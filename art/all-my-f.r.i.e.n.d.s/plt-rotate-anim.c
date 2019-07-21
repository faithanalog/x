#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <stdint.h>
#include <math.h>

// 512/(((1/(bpm/60.0))*4.0)*framerate)
// 97, 29.97
// #define rotation_step 6.904682460238015
// 97, 25.0
// #define rotation_step 8.277333333333333
// 106, 26.767676767676768
#define rotation_step 8.448
#define frames 1100

#define width 1280
#define height 720
#define HEADER_BYTES "P6\n1280 720\n255"

#define plt_width 512
#define plt_height 256

#define rotation_mask 0x1ffff

uint8_t pixels[width * height * 3];
uint8_t palette[plt_width * plt_height * 3];

//P6             3
//1920 1080     10
//255            4
//              17
//
//P6             3
//512 256        8
//255            4
//              15
char header[32];



void read_palette() {
    FILE* f = fopen("allmyfriends.ppm", "rb");
    // Skip header
    fread(header, 1, 15, f);
    fread(palette, 1, plt_width * plt_height * 3, f);
    fclose(f);
}

void read_frame(int frame) {
    char buf[32];
    sprintf(buf, "in-frames/image%06d.ppm", frame + 1);
    FILE* f = fopen(buf, "rb");
    // Skip header
    fread(header, 1, sizeof(HEADER_BYTES), f);
    fread(pixels, 1, width * height * 3, f);
    fclose(f);
}

void write_frame(int frame) {
    char buf[32];
    sprintf(buf, "ot-frames/image-%06d.ppm", frame + 1);
    FILE* f = fopen(buf, "wb");
    fwrite(header, 1, sizeof(HEADER_BYTES), f);
    fwrite(pixels, 1, width * height * 3, f);
    fclose(f);
}

float srgb_to_linear(float x) {
  if (x <= 0.0404482362771082) {
    return x / 12.92;
  } else {
    return pow((x + 0.055) / 1.055, 2.4);
  }
}

float srgb8_to_y_lut[256 * 3];

int main() {
    for (size_t i = 0; i < 256; i++) {
      srgb8_to_y_lut[i + 0x000] = 0.17697 * srgb_to_linear(i / 255.0) * (plt_width - 1);
      srgb8_to_y_lut[i + 0x100] = 0.81240 * srgb_to_linear(i / 255.0) * (plt_width - 1);
      srgb8_to_y_lut[i + 0x200] = 0.01063 * srgb_to_linear(i / 255.0) * (plt_width - 1);
    }

    read_palette();

    float rotation = 0;
    for (int i = 0; i < frames; i++) {
        printf("frame %d\n", i + 1);
        read_frame(i);
        for (size_t pidx = 0; pidx < width * height * 3; pidx += 3) {
            int r = (int)pixels[pidx + 0] & 0xFF;
            int g = (int)pixels[pidx + 1] & 0xFF;
            int b = (int)pixels[pidx + 2] & 0xFF;
            float y = srgb8_to_y_lut[r + 0x000] + srgb8_to_y_lut[g + 0x100] + srgb8_to_y_lut[b + 0x200];
            size_t idx = ((size_t)(y + rotation) & rotation_mask) * 3;
            memcpy(pixels + pidx, palette + idx, 3);
        }
        write_frame(i);
        rotation = rotation + rotation_step;
        if (rotation > plt_width * plt_height) {
            rotation -= plt_width * plt_height;
        }
    }
}
