package main

import "vendor:sdl2"
import sdl_ttf "vendor:sdl2/ttf"
import "core:fmt"
import "core:image/png"
import "core:strings"
import "core:strconv"
import "core:math"

Direction :: enum {right, left}

Sprite :: struct {
    width: u64,
    height: u64,
    pixels: [dynamic]u32,
    spriteWidth: u64,
    spriteHeight: u64,
    animSpeed: f64,
    framePos: f64,
    lastFrameAnim: u64, // last frame of the animation, to loop to
    direction: Direction,
    stationary: bool,
}

TileSet :: struct {
    width: u64,
    height: u64,
    pixels: [dynamic]u32,
    tileIndex: u64,
    tileWidth: u64,
    tileHeight: u64,
}

Vec2 :: struct {
    x: int,
    y: int,
}

Player :: struct {
    direction: Direction,
    stationary: bool,
}

Ctx :: struct {
    width: u64,
    height: u64,
    frameStart: f64,
    frameEnd: f64,
    frameElapsed: f64,
    sceneScaling: u64,
    isRunning: bool,
}

SDL :: struct {
    renderer: ^sdl2.Renderer, 
    window: ^sdl2.Window, 
    texture: ^sdl2.Texture,
    message: ^sdl2.Texture,
    font: ^sdl_ttf.Font,
    fontColour: sdl2.Colour,
    surfaceMessage: ^sdl2.Surface,
    messageRect: sdl2.Rect,
}

process_input :: proc(isRunning: ^bool, player: ^Player) {
    event: sdl2.Event

    for sdl2.PollEvent(&event) {
        #partial switch(event.type) {
        case .QUIT:
            isRunning^ = false
        case .KEYDOWN:
			#partial switch(event.key.keysym.sym) {
			case .ESCAPE:
                isRunning^ = false
            case .RIGHT:
                player.direction = Direction.right
                player.stationary = false
            case.d:
                player.direction = Direction.right
                player.stationary = false
            case.a:
                player.direction = Direction.left
                player.stationary = false
            case .LEFT:
                player.direction = Direction.left
                player.stationary = false
            }
        case .KEYUP:
			#partial switch(event.key.keysym.sym) {
            case .RIGHT:
                player.direction = Direction.right
                player.stationary = true
            case.d:
                player.direction = Direction.right
                player.stationary = true
            case.a:
                player.direction = Direction.left
                player.stationary = true
            case .LEFT:
                player.direction = Direction.left
                player.stationary = true
            }
        }
    }
}

load_from_png :: proc(spriteFile: string, array: ^[dynamic]u32) -> (width:u64, height: u64) {
    spriteUnpacked, sprite_err := png.load(spriteFile) // returns the spriteUnpacked as RGBA, each as separate array entry (width * depth * channels)
    if sprite_err != nil {
        fmt.println(strings.concatenate({string("Could't load png: "), spriteFile}))
    }

    resize(array, spriteUnpacked.width * spriteUnpacked.height)
    
    width = u64(spriteUnpacked.width)
    height = u64(spriteUnpacked.height)
    spritePixel: u32

    for i := 0; i < (spriteUnpacked.width * spriteUnpacked.height * spriteUnpacked.channels); i += 4 {
        spritePixel = u32(spriteUnpacked.pixels.buf[i]) << 24 + u32(spriteUnpacked.pixels.buf[i + 1]) << 16 + u32(spriteUnpacked.pixels.buf[i + 2]) << 8 + u32(spriteUnpacked.pixels.buf[i + 3])
        spritePixel = u32(spriteUnpacked.pixels.buf[i + 3]) << 24 + u32(spriteUnpacked.pixels.buf[i + 2]) << 16 + u32(spriteUnpacked.pixels.buf[i + 1]) << 8 + u32(spriteUnpacked.pixels.buf[i])
        array^[i / 4] = spritePixel
    }

    return width, height
}

draw_tile :: proc(tileSet: ^TileSet, pixelArray: ^[dynamic]u32, index: u64, ctx: ^Ctx) {
    /*
    for y in 0 ..< tileSet.tileHeight {
        for x in 0 ..< tileSet.tileWidth {
            //if (coords.x + int(x) < sceneInfo.x) && (coords.y + int(y) < sceneInfo.y) {
                pixelArray[ctx.width * y + x] = tileSet.pixels[tileSet.width * y + x]
                //pixelArray[sceneInfo.x * (int(y) + coords.y) + int(x) + coords.x] = sprite.pixels[sprite.width * (y + 8) + x * sprite.spriteWidth]
            //}
        }
    }
    */

    for y in 0 ..< u64(96) {
        for x in 0 ..< u64(192) {
            pixelArray[ctx.width * y + x] = tileSet.pixels[192 * y + x]
        }
    }
}

draw_sprite_static :: proc(sprite: ^Sprite, pixelArray: ^[dynamic]u32, coords: Vec2, sceneInfo: Vec2) {
    for y in 0 ..< sprite.spriteHeight {
        for x in 0 ..< sprite.spriteWidth {
            if (coords.x + int(x) < sceneInfo.x) && (coords.y + int(y) < sceneInfo.y) {
                pixelArray[sceneInfo.x * (int(y) + coords.y) + int(x) + coords.x] = sprite.pixels[sprite.width * (y + 8) + x * sprite.spriteWidth]
            }
        }
    }
}

draw_sprite_dynamic :: proc(sprite: ^Sprite, pixelArray: ^[dynamic]u32, coords: Vec2, sceneInfo: Vec2, dt: f64) {
    sprite.framePos += dt * sprite.animSpeed
    if sprite.framePos > f64(sprite.lastFrameAnim) + 0.5 {
        sprite.framePos = 0
    }
    spriteIndex: u64 = u64(math.round(sprite.framePos))

    if sprite.direction == Direction.right {
        for y in 0 ..< sprite.spriteHeight {
            for x in 0 ..< sprite.spriteWidth {
                if (coords.x + int(x) < sceneInfo.x) && (coords.y + int(y) < sceneInfo.y) {
                    pixelArray[sceneInfo.x * (int(y) + coords.y) + int(x) + coords.x] = sprite.pixels[sprite.width * (y + 32) + x + spriteIndex * sprite.spriteWidth]
                }
            }
        }
    } else if sprite.direction == Direction.left {
        for y in 0 ..< sprite.spriteHeight {
            for x in 0 ..< sprite.spriteWidth {
                if (coords.x + int(x) < sceneInfo.x) && (coords.y + int(y) < sceneInfo.y) {
                    pixelArray[sceneInfo.x * (int(y) + coords.y) + int(sprite.spriteWidth) - int(x) + coords.x] = sprite.pixels[sprite.width * (y + 32) + x + spriteIndex * sprite.spriteWidth]
                }
            }
        }
    }
}

scale_scene :: proc(scene: ^[dynamic]u32, scaledScene: ^[dynamic]u32, ctx: Ctx) {
    scaledWidth := ctx.width * ctx.sceneScaling

    for y in 0 ..< ctx.height {
        for x in 0 ..< ctx.width {
            for j in 0 ..< ctx.sceneScaling {
               for i in 0 ..< ctx.sceneScaling {
                    scaledScene^[(ctx.sceneScaling * y + j) * scaledWidth + x * ctx.sceneScaling + i] = scene^[y * ctx.width + x]
                }
            }
        }
    }
}

// create better function that can take a string and print it to the screen
sdl_ttf_init :: proc(fontPath: string, renderer: ^sdl2.Renderer) -> ^sdl2.Texture {
    init_font := sdl_ttf.Init()
	assert(init_font == 0, sdl2.GetErrorString())

    font := sdl_ttf.OpenFont(strings.clone_to_cstring(fontPath), 20)
	assert(font != nil, sdl2.GetErrorString())

    white := sdl2.Colour{255, 255 ,255 ,255}
    surfaceMessage := sdl_ttf.RenderText_Solid(font, "Hello, world!", white)
    message := sdl2.CreateTextureFromSurface(renderer, surfaceMessage)
    sdl2.FreeSurface(surfaceMessage)

    return message
}

sdl_init :: proc(ctx: ^Ctx) -> SDL {
    assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())
    window := sdl2.CreateWindow("Le SDL", sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, i32(ctx.width) * i32(ctx.sceneScaling), i32(ctx.height) * i32(ctx.sceneScaling), sdl2.WINDOW_SHOWN)
    assert(window != nil, sdl2.GetErrorString())
    renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
    assert(renderer != nil, sdl2.GetErrorString())

    rmask: u32 = 0x000000ff
    gmask: u32 = 0x0000ff00
    bmask: u32 = 0x00ff0000
    amask: u32 = 0xff000000
    
    tempSurface := sdl2.CreateRGBSurface(0, i32(ctx.width) * i32(ctx.sceneScaling), i32(ctx.height) * i32(ctx.sceneScaling), 32, rmask, gmask, bmask, amask)
    texture := sdl2.CreateTextureFromSurface(renderer, tempSurface)
    sdl2.FreeSurface(tempSurface)

    // font init
    init_font := sdl_ttf.Init()
	assert(init_font == 0, sdl2.GetErrorString())
    hack := sdl_ttf.OpenFont(`sdl/hack.ttf`, 20)
	assert(hack != nil, sdl2.GetErrorString())
    white := sdl2.Colour{255, 255 ,255 ,255}
    surfaceMessage := sdl_ttf.RenderText_Solid(hack, "Hello, world!", white)
    message := sdl2.CreateTextureFromSurface(renderer, surfaceMessage)
    sdl2.FreeSurface(surfaceMessage)

    messageRect: sdl2.Rect
    messageRect.x = 2680
    messageRect.y = 0
    messageRect.w = 200
    messageRect.h = 100

    ctx^.isRunning = true

    sdl: SDL = {renderer, window, texture, message, hack, white, surfaceMessage, messageRect}
    return sdl
}

debug_type :: proc(item: typeid) {
    fmt.println(typeid_of(type_of(item))) 
}

sdl_render :: proc(width, height: i32) {
    ctx: Ctx

    ctx.sceneScaling = 6
    ctx.width = u64(width)
    ctx.height = u64(height)

    sdl := sdl_init(&ctx)
    defer {
        sdl2.Quit()
        sdl2.DestroyWindow(sdl.window)
        sdl2.DestroyRenderer(sdl.renderer)
        sdl2.DestroyTexture(sdl.texture)
        sdl2.DestroyTexture(sdl.message)
        sdl_ttf.Quit()
    }


    tileSet: TileSet
    tileSet.width, tileSet.height = load_from_png(`sdl/rocky_roads/Tilesets/tileset_forest.png`, &tileSet.pixels)
    tileSet.tileWidth = 16
    tileSet.tileHeight = 16
    satyr: Sprite
    satyr.width, satyr.height = load_from_png(`sdl/satyr-Sheet.png`, &satyr.pixels)
    satyr.spriteWidth = 32
    satyr.spriteHeight = 32
    satyr.animSpeed = 10
    satyr.lastFrameAnim = 7
    satyr.direction = Direction.left

    player: Player
    player.stationary = true

    scene := [dynamic]u32{}
    resize(&scene, int(height * width))

    scaledScene := [dynamic]u32{}
    resize(&scaledScene, int(ctx.width * ctx.height * ctx.sceneScaling * ctx.sceneScaling))

    spriteCoords: Vec2
    tempY: f64

    buf: [10]byte
    x := 0

    app_start := f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency())
    frame_start: f64 = app_start
    frame_end: f64
    frame_elapsed: f64 = 0.001

    tempX: f64


    for ctx.isRunning {
        process_input(&ctx.isRunning, &player)

        draw_tile(&tileSet, &scene, 0, &ctx)

        satyr.direction = player.direction

        if player.stationary == false {
        if satyr.direction == Direction.right {
            tempX += frame_elapsed * 50
        } else if satyr.direction == Direction.left {
            tempX -= frame_elapsed * 50
        }
            spriteCoords.x = int(tempX)
        }

        //tempY += frame_elapsed * 50
        //spriteCoords.y = int(tempY)
        spriteCoords.y = int(ctx.height - satyr.spriteHeight) + 3

        draw_sprite_dynamic(&satyr, &scene, spriteCoords, Vec2{int(width), int(height)}, frame_elapsed)

        scale_scene(&scene, &scaledScene, ctx)

        sdl2.UpdateTexture(sdl.texture, nil, raw_data(scaledScene), width * i32(ctx.sceneScaling) * size_of(u32))

        sdl.surfaceMessage = sdl_ttf.RenderText_Solid(sdl.font, strings.clone_to_cstring(strconv.ftoa(buf[:], 1 / frame_elapsed, 'f', 2, 64)), sdl.fontColour)
        sdl.message = sdl2.CreateTextureFromSurface(sdl.renderer, sdl.surfaceMessage)

        srcRect, bounds: sdl2.Rect
        srcRect.x = 0
        srcRect.y = 0
        srcRect.w = width * i32(ctx.sceneScaling)
        srcRect.h = height * i32(ctx.sceneScaling)
        bounds = srcRect
        sdl2.RenderCopy(sdl.renderer, sdl.texture, &srcRect, &bounds)
        sdl2.RenderCopy(sdl.renderer, sdl.message, nil, &sdl.messageRect)
        sdl2.RenderPresent(sdl.renderer)
        sdl2.RenderClear(sdl.renderer)
        
        // cleaning up scene
        for y in 0 ..< ctx.height {
            for x in 0 ..< ctx.width {
                scene[y * ctx.width + x] = 0
            }
        }

        frame_end     = f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency())
		frame_elapsed = frame_end - frame_start
		frame_start   = frame_end
    }
}
