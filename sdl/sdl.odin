package main

import "vendor:sdl2"
import "core:fmt"
import "core:image/png"
import "core:strings"

process_input :: proc(isRunning: ^bool) {
    event: sdl2.Event

    for sdl2.PollEvent(&event) {
        #partial switch(event.type) {
        case .QUIT:
            isRunning^ = false
        case .KEYDOWN:
			#partial switch(event.key.keysym.sym) {
			case .ESCAPE:
                isRunning^ = false
            }
        }
    }
}

load_sprite :: proc(spriteFile: string) -> ^[dynamic]u32 {
    spriteUnpacked, sprite_err := png.load(spriteFile) // returns the spriteUnpacked as RGBA, each as separate array entry (width * depth * channels)
    if sprite_err != nil {
        fmt.println(strings.concatenate({string("Could't load png: "), spriteFile}))
    }

    spriteArray := [dynamic]u32{}
    spritePixel: u32
    resize(&spriteArray, spriteUnpacked.width * spriteUnpacked.height)
    
    for i := 0; i < (spriteUnpacked.width * spriteUnpacked.height * spriteUnpacked.channels); i += 4 {
        spritePixel = u32(spriteUnpacked.pixels.buf[i]) << 24 + u32(spriteUnpacked.pixels.buf[i + 1]) << 16 + u32(spriteUnpacked.pixels.buf[i + 2]) << 8 + u32(spriteUnpacked.pixels.buf[i + 3])
        spriteArray[i / 4] = spritePixel
    }

    return &spriteArray
}

sdl_render :: proc(width, height: i32) {
    assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())
	defer sdl2.Quit()

    window := sdl2.CreateWindow("Le SDL", sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, width, height, sdl2.WINDOW_SHOWN)
    assert(window != nil, sdl2.GetErrorString())
    defer sdl2.DestroyWindow(window)

    renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
    assert(renderer != nil, sdl2.GetErrorString())
    defer sdl2.DestroyRenderer(renderer)

    spriteArray := load_sprite(`sdl/art.png`)
    sprite := spriteArray^

    rmask: u32 = 0x000000ff
    gmask: u32 = 0x0000ff00
    bmask: u32 = 0x00ff0000
    amask: u32 = 0xff000000

    tempSurface := sdl2.CreateRGBSurface(0, width, height, 32, rmask, gmask, bmask, amask)
    texture := sdl2.CreateTextureFromSurface(renderer, tempSurface)
    sdl2.FreeSurface(tempSurface)

    isRunning := true

    tempPixels := [dynamic]u32{}
    resize(&tempPixels, int(height * width))

    pixelBuffer := [800 * 800]rgb{}
    pixelColour: u32

    for isRunning {
        process_input(&isRunning)
        createFrame(width, height, &pixelBuffer)

        for y in 0 ..< 300 {
            for x in 0 ..< 300 {
                tempPixels[int(width) * y + x] = sprite[300 * y + x]
            }
        }
        sdl2.UpdateTexture(texture, nil, raw_data(tempPixels), width * size_of(u32))

        for y in 0 ..< height {
            for x in 0 ..< width {
                tempPixels[y * width + x] = 0
            }
        }

        srcRect, bounds: sdl2.Rect
        srcRect.x = 0
        srcRect.y = 0
        srcRect.w = width
        srcRect.h = height
        bounds = srcRect
        sdl2.RenderCopy(renderer, texture, &srcRect, &bounds)
        sdl2.RenderPresent(renderer)
    }
}
