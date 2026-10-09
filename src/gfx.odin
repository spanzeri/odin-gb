package odin_gb

import sdl "vendor:sdl3"
import "core:log"

GfxContext :: struct {
    window: ^sdl.Window,
    renderer: ^sdl.Renderer,
    texture: ^sdl.Texture,
    event: sdl.Event,
}

gfx_context_make :: proc(width, height: i32, scale := i32(1), title: cstring) -> (ctx: GfxContext, ok: bool) {
    if !sdl.CreateWindowAndRenderer(title, width * scale, height * scale, {}, &ctx.window, &ctx.renderer) {
        log.errorf("Failed to create window and renderer with error: {}", sdl.GetError())
        return
    }
    defer if !ok do gfx_context_delete(&ctx)

    ctx.texture = sdl.CreateTexture(ctx.renderer, .RGBA8888, .STREAMING, width, height)
    if ctx.texture == nil {
        log.errorf("Failed to create framebuffer texture with error: {}", sdl.GetError())
        return
    }
    sdl.SetTextureScaleMode(ctx.texture, .NEAREST)

    // sdl.SetRenderVSync(ctx.renderer, 1)
    return ctx, true
}

gfx_context_delete :: proc(ctx: ^GfxContext) {
    if ctx != nil {
        if ctx.texture != nil do sdl.DestroyTexture(ctx.texture)
        if ctx.renderer != nil do sdl.DestroyRenderer(ctx.renderer)
        if ctx.window != nil do sdl.DestroyWindow(ctx.window)

        ctx^ = {}
    }
}

gfx_clear :: proc(ctx: GfxContext, color: sdl.Color) {
    sdl.SetRenderDrawColor(ctx.renderer, color.r, color.g, color.b, color.a)
    sdl.RenderClear(ctx.renderer)
}

gfx_put_pixel :: proc(ctx: GfxContext, x, y: i32, color: sdl.Color) {
    sdl.SetRenderDrawColor(ctx.renderer, color.r, color.g, color.b, color.a)
    sdl.RenderPoint(ctx.renderer, cast(f32)x, cast(f32)y)
}

gfx_update :: proc(ctx: GfxContext) {
    sdl.RenderPresent(ctx.renderer)
}

