package main

import "vendor:sdl2"
import "core:fmt"

main :: proc() {
        width: i32: 800
        height: i32: 800
        sdl_render(width, height)
}
