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

load_sprite :: proc(spriteFile: string) -> ^Sprite {
    spriteUnpacked, sprite_err := png.load(spriteFile) // returns the spriteUnpacked as RGBA, each as separate array entry (width * depth * channels)
    if sprite_err != nil {
        fmt.println(strings.concatenate({string("Could't load png: "), spriteFile}))
    }

    sprite: Sprite
    spritePixel: u32
    resize(&sprite.pixels, spriteUnpacked.width * spriteUnpacked.height)
    
    sprite.width = u64(spriteUnpacked.width)
    sprite.height = u64(spriteUnpacked.height)

    for i := 0; i < (spriteUnpacked.width * spriteUnpacked.height * spriteUnpacked.channels); i += 4 {
        spritePixel = u32(spriteUnpacked.pixels.buf[i]) << 24 + u32(spriteUnpacked.pixels.buf[i + 1]) << 16 + u32(spriteUnpacked.pixels.buf[i + 2]) << 8 + u32(spriteUnpacked.pixels.buf[i + 3])
        spritePixel = u32(spriteUnpacked.pixels.buf[i + 3]) << 24 + u32(spriteUnpacked.pixels.buf[i + 2]) << 16 + u32(spriteUnpacked.pixels.buf[i + 1]) << 8 + u32(spriteUnpacked.pixels.buf[i])
        sprite.pixels[i / 4] = spritePixel
    }

    return &sprite
}

draw_sprite :: proc(sprite: ^Sprite, pixelArray: ^[dynamic]u32, coords: Vec2, sceneInfo: Vec2, dt: f64) {
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

debug_type :: proc(item: any) {
    fmt.println(typeid_of(type_of(item))) 
}

sdl_render :: proc(width, height: i32) {
    ctx: Ctx

    ctx.sceneScaling = 6
    ctx.width = u64(width)
    ctx.height = u64(height)

    assert(sdl2.Init(sdl2.INIT_EVERYTHING) == 0, sdl2.GetErrorString())
	defer sdl2.Quit()

    window := sdl2.CreateWindow("Le SDL", sdl2.WINDOWPOS_CENTERED, sdl2.WINDOWPOS_CENTERED, width * i32(ctx.sceneScaling), height * i32(ctx.sceneScaling), sdl2.WINDOW_SHOWN)
    assert(window != nil, sdl2.GetErrorString())
    defer sdl2.DestroyWindow(window)
    renderer := sdl2.CreateRenderer(window, -1, sdl2.RENDERER_ACCELERATED)
    assert(renderer != nil, sdl2.GetErrorString())
    defer sdl2.DestroyRenderer(renderer)

    sprite := load_sprite(`sdl/rocky_roads/Tilesets/tileset_forest.png`)^
    sprite.spriteWidth = sprite.width
    sprite.spriteHeight = sprite.height
    satyr := load_sprite(`sdl/satyr-Sheet.png`)^
    satyr.spriteWidth = 32
    satyr.spriteHeight = 32
    satyr.animSpeed = 10
    satyr.lastFrameAnim = 7
    satyr.direction = Direction.left

    player: Player
    player.stationary = true

    rmask: u32 = 0x000000ff
    gmask: u32 = 0x0000ff00
    bmask: u32 = 0x00ff0000
    amask: u32 = 0xff000000
    
    tempSurface := sdl2.CreateRGBSurface(0, width * i32(ctx.sceneScaling), height * i32(ctx.sceneScaling), 32, rmask, gmask, bmask, amask)
    texture := sdl2.CreateTextureFromSurface(renderer, tempSurface)
    sdl2.FreeSurface(tempSurface)

    isRunning := true

    scene := [dynamic]u32{}
    resize(&scene, int(height * width))

    scaledScene := [dynamic]u32{}
    resize(&scaledScene, int(ctx.width * ctx.height * ctx.sceneScaling * ctx.sceneScaling))

    spriteCoords: Vec2
    tempY: f64
    
    // font init
    init_font := sdl_ttf.Init()
	assert(init_font == 0, sdl2.GetErrorString())
    hack := sdl_ttf.OpenFont(`sdl/hack.ttf`, 20)
	assert(hack != nil, sdl2.GetErrorString())
    white := sdl2.Colour{255, 255 ,255 ,255}
    surfaceMessage := sdl_ttf.RenderText_Solid(hack, "Hello, world!", white)
    message := sdl2.CreateTextureFromSurface(renderer, surfaceMessage)
    sdl2.FreeSurface(surfaceMessage)
    defer sdl2.DestroyTexture(message)
    defer sdl_ttf.Quit()

    messageRect : sdl2.Rect
    messageRect.x = 2680
    messageRect.y = 0
    messageRect.w = 200
    messageRect.h = 100
    buf: [10]byte
    x := 0

    app_start := f64(sdl2.GetPerformanceCounter()) / f64(sdl2.GetPerformanceFrequency())
    frame_start: f64 = app_start
    frame_end: f64
    frame_elapsed: f64 = 0.001

    tempX: f64


    for isRunning {
        process_input(&isRunning, &player)

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

        draw_sprite(&satyr, &scene, spriteCoords, Vec2{int(width), int(height)}, frame_elapsed)

        scale_scene(&scene, &scaledScene, ctx)

        sdl2.UpdateTexture(texture, nil, raw_data(scaledScene), width * i32(ctx.sceneScaling) * size_of(u32))

        surfaceMessage = sdl_ttf.RenderText_Solid(hack, strings.clone_to_cstring(strconv.ftoa(buf[:], 1 / frame_elapsed, 'f', 2, 64)), white)
        message = sdl2.CreateTextureFromSurface(renderer, surfaceMessage)

        srcRect, bounds: sdl2.Rect
        srcRect.x = 0
        srcRect.y = 0
        srcRect.w = width * i32(ctx.sceneScaling)
        srcRect.h = height * i32(ctx.sceneScaling)
        bounds = srcRect
        sdl2.RenderCopy(renderer, texture, &srcRect, &bounds)
        sdl2.RenderCopy(renderer, message, nil, &messageRect)
        sdl2.RenderPresent(renderer)
        sdl2.RenderClear(renderer)
        
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
