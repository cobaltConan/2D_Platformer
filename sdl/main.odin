package main

import "vendor:sdl2"
import "core:fmt"

main :: proc() {
        width: i32: 480
        height: i32: 270
        sdl_render(width, height)
}
