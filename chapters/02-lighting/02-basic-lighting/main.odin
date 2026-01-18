package main

import "core:log"
import "core:mem"
import "vendor:glfw"

WINDOW_WIDTH  :: 800
WINDOW_HEIGHT :: 600
WINDOW_TITLE  :: "gl"
GL_VERSION_MAJOR :: 3
GL_VERSION_MINOR :: 3
VERTEX_SHADER :: "./shaders/default.vs"
FRAGMENT_SHADER :: "./shaders/default.fs"
VERTEX_SHADER_LIGHT :: "./shaders/light.vs"
FRAGMENT_SHADER_LIGHT :: "./shaders/light.fs"
AMBIENT_STRENGTH :: 0.1
SPECULAR_STRENGTH :: 0.5


main :: proc() {
    // Tracking allocator and logger set up
    defer free_all(context.temp_allocator)
    context.logger = log.create_console_logger()
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer mem_check_leaks(&tracking_allocator)

    // Program initialization
    game := &Game{
        models = make([dynamic]Model),
        camera = &Camera{
            pos   = {0.0, 0.0, 0.0},
            up    = {0, 1, 0},
            front = {0, 0, -1},
            speed = 2.5,
            yaw   = -90,
            pitch = 0,
            fov   = 45.0,
        },
    }
    game_init(game)
    defer game_exit(game)

    // Model initialization
    cube := &Model{}
    // Set vertices
    cube_verts := [?]f32 {
        // Vertex coords:   Normals:
        // Face #1
        -0.5, -0.5, -0.5,    0.0,  0.0, -1.0,
         0.5, -0.5, -0.5,    0.0,  0.0, -1.0,
         0.5,  0.5, -0.5,    0.0,  0.0, -1.0,
         0.5,  0.5, -0.5,    0.0,  0.0, -1.0,
        -0.5,  0.5, -0.5,    0.0,  0.0, -1.0,
        -0.5, -0.5, -0.5,    0.0,  0.0, -1.0,
        // Face #2
        -0.5, -0.5,  0.5,    0.0,  0.0,  1.0,
         0.5, -0.5,  0.5,    0.0,  0.0,  1.0,
         0.5,  0.5,  0.5,    0.0,  0.0,  1.0,
         0.5,  0.5,  0.5,    0.0,  0.0,  1.0,
        -0.5,  0.5,  0.5,    0.0,  0.0,  1.0,
        -0.5, -0.5,  0.5,    0.0,  0.0,  1.0,
        // Face #3
        -0.5,  0.5,  0.5,   -1.0,  0.0,  0.0,
        -0.5,  0.5, -0.5,   -1.0,  0.0,  0.0,
        -0.5, -0.5, -0.5,   -1.0,  0.0,  0.0,
        -0.5, -0.5, -0.5,   -1.0,  0.0,  0.0,
        -0.5, -0.5,  0.5,   -1.0,  0.0,  0.0,
        -0.5,  0.5,  0.5,   -1.0,  0.0,  0.0,
        // Face #4
         0.5,  0.5,  0.5,    1.0,  0.0,  0.0,
         0.5,  0.5, -0.5,    1.0,  0.0,  0.0,
         0.5, -0.5, -0.5,    1.0,  0.0,  0.0,
         0.5, -0.5, -0.5,    1.0,  0.0,  0.0,
         0.5, -0.5,  0.5,    1.0,  0.0,  0.0,
         0.5,  0.5,  0.5,    1.0,  0.0,  0.0,
         // Face #5
        -0.5, -0.5, -0.5,    0.0, -1.0,  0.0,
         0.5, -0.5, -0.5,    0.0, -1.0,  0.0,
         0.5, -0.5,  0.5,    0.0, -1.0,  0.0,
         0.5, -0.5,  0.5,    0.0, -1.0,  0.0,
        -0.5, -0.5,  0.5,    0.0, -1.0,  0.0,
        -0.5, -0.5, -0.5,    0.0, -1.0,  0.0,
        // Face #6
        -0.5,  0.5, -0.5,    0.0,  1.0,  0.0,
         0.5,  0.5, -0.5,    0.0,  1.0,  0.0,
         0.5,  0.5,  0.5,    0.0,  1.0,  0.0,
         0.5,  0.5,  0.5,    0.0,  1.0,  0.0,
        -0.5,  0.5,  0.5,    0.0,  1.0,  0.0,
        -0.5,  0.5, -0.5,    0.0,  1.0,  0.0,
    }
    model_new(&game.models, cube_verts[:])
    model_new(&game.models, cube_verts[:])

    // Light initialization
    game.light = &Entity{
        pos   = { 0.0,  0.0, -5.0},
        scale = { 0.2,  0.2,  0.2},
        color = { 1.0,  1.0,  1.0},
        model = &game.models[0]
    }
    
    // Entity initialization
    append(
        &game.entities,
        Entity{
            pos   = { 0.0,  0.0, -6.0},
            scale = { 1.0,  1.0,  1.0},
            color = { 1.0,  0.5,  0.3},
            model = &game.models[1]
        }
    )

    // Time measurement variables
    time_current: f64
    time_prev: f64
    dt: f64

    // Main Loop
    for !glfw.WindowShouldClose(game.window) {
        time_current = glfw.GetTime()
        dt = time_current - time_prev
        time_prev = time_current
        game_input(game, dt)
        game_update(game, dt)
        game_render(game)
        glfw.PollEvents()
        mem_check_bad_free(&tracking_allocator)
    }
}