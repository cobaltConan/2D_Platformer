package main

import "core:fmt"
import "core:os"
import "core:strings"

rgb :: struct {
    r: u8,
    g: u8,
    b: u8,
}

createFrame :: proc(width, height: i32, pixelBuffer: ^[800 * 800]rgb) {
    
    for y in 0..< height {
        for x in 0..< i32(100) {
            pixelBuffer^[height * y + x].r = 255
            pixelBuffer^[height * y + x].g = 255
            pixelBuffer^[height * y + x].b = 255
        }
    }
}
