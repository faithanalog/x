fn main() {
    // header for a 220x220 RGB ppm file
    println!("P3");
    println!("220 220");
    println!("255");

    for y in 0..220 {
        let mut buf = [0x404040; 220];
        draw_twister(&mut buf, y);
        print_ppm_line(&buf);
    }
}

fn print_ppm_line(buf: &[u32]) {
    for pix in buf {
        let bytes = pix.to_be_bytes();
        print!("{} {} {} ", bytes[1], bytes[2], bytes[3])
    }
    println!();
}


fn draw_line(buf: &mut [u32], color: u32, x0: usize, x1: usize) {
    for i in x0 .. x1 {
        if i >= 0 && i < 220 {
            buf[i] = color;
        }
    }
}

fn draw_twister(buf: &mut [u32], row: usize) {
    let y = row as f32;

    let a_in = y / 220.0 * 4.0;
    let a = (y / 40.0 + (y/30.0).cos() * std::f32::consts::PI).cos() * std::f32::consts::PI;
    let deg90 = std::f32::consts::FRAC_PI_2;
    let deg180 = std::f32::consts::PI;
    let deg270 = deg90 + deg180;

    //let xoff = (y / 20.0).sin() * 0.25 + (y / 10.0).cos() * 0.15;
    //let xoff = y / 100.0;
    let xoff = 0.0;

    let x0 = a.sin() + xoff;
    let x1 = (a + deg90).sin() + xoff;
    let x2 = (a + deg180).sin() + xoff;
    let x3 = (a + deg270).sin() + xoff;

    let pairs = [
        TwisterPair{l: x0, r: x1, col: 0xFF0080},
        TwisterPair{l: x1, r: x2, col: 0x00FF00},
        TwisterPair{l: x2, r: x3, col: 0x00C0FF},
        TwisterPair{l: x3, r: x0, col: 0xFFC000},
    ];

    for pair in pairs {
        if pair.r >= pair.l {
            let l = ((pair.l + 1.0) * 60.0 + 60.0) as usize;
            let r = ((pair.r + 1.0) * 60.0 + 60.0) as usize;
            draw_line(buf, pair.col, l, r);
            draw_line(buf, 0x000000, l - 2, l + 2);
            draw_line(buf, 0x000000, r - 2, r + 2);
        }
    }
}

struct TwisterPair {
    l: f32,
    r: f32,
    col: u32
}
