def tick args
  defaults args
  calc args
  render args
end

def defaults args
  args.state.pen ||= {
    path: "sprites/chroma-noir-8x8/items.png",
    x: 500,
    y: 500,
    w: 32,
    h: 32,
    tile_x: 8 * 2,
    tile_w: 8,
    tile_h: 8,
    angle: 180,
    dx: 0.0,
    dy: 0.0,
  }
  
  args.state.canvas_box_rect ||= {
    x: Grid.w / 2 - 256,
    y: Grid.h / 2 - 256,
    w: 512,
    h: 512,
    angle: 0,
  }

  args.outputs[:canvas_box].w = 1024
  args.outputs[:canvas_box].h = 1024
   
  args.outputs[:canvas_box].sprites << {
    x: 256,
    y: 256,
    w: 512,
    h: 512,
    angle: args.state.canvas_box_rect[:angle],
    r: 13,
    g: 13,
    b: 13,
  }
end

def calc args
  # inputs
  args.state.canvas_box_rect[:angle] += 2.0 if args.inputs.keyboard.a
  args.state.canvas_box_rect[:angle] -= 2.0 if args.inputs.keyboard.d

  # base gravity
  args.state.pen[:dy] -= 0.5
  
  args.state.pen[:x] += args.state.pen[:dx]
  args.state.pen[:y] += args.state.pen[:dy].clamp(-5, 5)

  # collision handling
  min_x = args.state.canvas_box_rect[:x]
  max_x = args.state.canvas_box_rect[:x] + args.state.canvas_box_rect[:w] - args.state.pen[:w]
  min_y = args.state.canvas_box_rect[:y]
  max_y = args.state.canvas_box_rect[:y] + args.state.canvas_box_rect[:h] - args.state.pen[:h]

  if args.state.pen[:x] <= min_x
    args.state.pen[:x] = min_x
    args.state.pen[:dx] = 0
  elsif args.state.pen[:x] > max_x
    args.state.pen[:x] = max_x
    args.state.pen[:dx] = 0
  end

  if args.state.pen[:y] <= min_y
    args.state.pen[:y] = min_y
    args.state.pen[:dy] = 0
  elsif args.state.pen[:y] > max_y
    args.state.pen[:y] = max_y
    args.state.pen[:dy] = 0
  end

end

def render args
  args.outputs.solids << {
    x: 0,
    y: 0,
    w: 1280,
    h: 720,
    r: 0,
    g: 0,
    b: 0,
  }

  args.outputs.sprites << {
    x: Grid.w / 2 - 512,
    y: Grid.h / 2 - 512,
    w: 1024,
    h: 1024,
    # angle: args.state.canvas_box_rect[:angle],
    path: :canvas_box
  }

  args.outputs.sprites << args.state.pen
end
