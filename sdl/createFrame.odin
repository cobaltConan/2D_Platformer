package main

import "core:fmt"
import "core:os"
import "core:strings"

rgb :: struct {
    r: u8,
    g: u8,
    b: u8,
}

Sprite :: struct {
    width: int,
    height: int,
    pixels: [dynamic]u8,
}

createFrame :: proc(width, height: i32, pixelBuffer: ^[800 * 800]rgb) {
    
    for y in 0..< height {
        for x in 0..< i32(100) {
        //pixelBuffer^[height * y + y].r = 255
        //pixelBuffer^[height * y + y].g = 255
        //pixelBuffer^[height * y + y].b = 255
        pixelBuffer^[height * y + x].r = 255
        pixelBuffer^[height * y + x].g = 255
        pixelBuffer^[height * y + x].b = 255
        }
    }
}

loadSpritePPM :: proc(filepath: string) -> ^Sprite {
    sprite: Sprite

    data, ok := os.read_entire_file(filepath, context.allocator)

    if !ok {
        fmt.println("Errored when trying to access sprite")
    }

    for elem in data {
        fmt.println(elem)
        append(&sprite.pixels, elem)
    }

    return &sprite
}

