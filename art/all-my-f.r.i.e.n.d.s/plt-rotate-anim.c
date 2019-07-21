#include <stdio.h>
#include <stdint.h>

// 512/(((1/(bpm/60.0))*4.0)*framerate)
// 97, 29.97
// #define rotation_step 6.904682460238015
// 97, 25.0
// #define rotation_step 8.277333333333333
// 106, 26.767676767676768
#define rotation_step 8.448

#define width 1280
#define height 720

#define plt_width 512
#define plt_height 256

#define rotation_mask 0x1ffff

uint8_t in_pixels[width * height];
uint32_t out_pixels[width * height];

uint8_t in_palette[plt_width * plt_height * 3];
uint32_t palette[plt_width * plt_height];

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
    fread(in_palette, 1, plt_width * plt_height * 3, f);
    fclose(f);

    // No endian fuckery
    uint8_t* plt = (uint8_t*)palette;
    for (int i = 0; i < plt_width * plt_height; i++) {
        plt[i * 4 + 0] = 0xFF;
        plt[i * 4 + 1] = in_palette[i * 3 + 0];
        plt[i * 4 + 2] = in_palette[i * 3 + 1];
        plt[i * 4 + 3] = in_palette[i * 3 + 2];
    }
}

// Read grayscale frame from stdin
void read_frame() {
    fread(in_pixels, 1, width * height, stdin);
}

// Write argb frame to stdout
void write_frame() {
    fwrite(out_pixels, 4, width * height, stdout);
}

float grey_to_plt_lut[256];

int main() {
    for (int i = 0; i < 256; i++) {
      grey_to_plt_lut[i] = (i / 255.0) * (plt_width - 1);
    }

    read_palette();

    float rotation = 0;
    int frames = 1;
    while (1) {
        fprintf(stderr, "frame %d\n", frames);
        read_frame();
        for (size_t pidx = 0; pidx < width * height; pidx++) {
            float y = grey_to_plt_lut[in_pixels[pidx]];
            size_t idx = (size_t)(y + rotation) & rotation_mask;
            out_pixels[pidx] = palette[idx];
        }
        write_frame();
        frames++;
        rotation += rotation_step;
        if (rotation > plt_width * plt_height) {
            rotation -= plt_width * plt_height;
        }
    }
}
