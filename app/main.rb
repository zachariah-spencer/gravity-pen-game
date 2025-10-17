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
    tile_y: 1,
    tile_w: 7,
    tile_h: 7,
    angle: 180.0,
    dx: 0.0,
    dy: 0.0,
  }

  nil_or_one = [nil, nil, 1]

  args.state.rune_pixels ||= []
  if Kernel.tick_count == 0
    16.times { args.state.rune_pixels << [] }
    args.state.rune_pixels.each { |row| 16.times { row << nil_or_one.sample }}
  end
  
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
    r: 13,
    g: 13,
    b: 13,
  }

  args.state.rune_pixels.each_with_index do |pixel_row, row_index|
    pixel_row.each_with_index do |pixel, column_index|
      if pixel
        args.outputs[:canvas_box].primitives << {
          x: (256) + column_index * 32,
          y: (256 + 512 - 32) - row_index * 32,
          w: 32,
          h: 32,
          r: 0,
          g: 255,
          b: 255,
          a: 50,
          primitive_marker: :solid
        }
      end
    end
  end

  args.state.gravity_arrow ||= {
    x: Grid.w * 0.5 - 32,
    y: Grid.h * 0.5 - 32,
    w: 64,
    h: 64,
    angle: 0,
    path: "sprites/chroma-noir-8x8/patterns-and-symbols.png",
    tile_x: 8 * 6,
    tile_y: 0,
    tile_w: 8,
    tile_h: 8
  }
end

def calc args
  # local vars
  pen = args.state.pen
  box = args.state.canvas_box_rect
  arrow = args.state.gravity_arrow

  box_cx = box[:x] + box[:w] * 0.5
  box_cy = box[:y] + box[:h] * 0.5
  angle_deg = box[:angle]
  angle_rad = angle_deg * Math::PI / 180.0
  cos_a = Math.cos(angle_rad)
  sin_a = Math.sin(angle_rad)

  arrow_angle_deg = arrow[:angle]
  arrow_angle_rad = arrow_angle_deg * Math::PI / 180.0
  arrow_cos_a = Math.cos(arrow_angle_rad)
  arrow_sin_a = Math.sin(arrow_angle_rad)

  gravity_strength = 0.5
  max_velocity = 10

  # inputs
  args.state.canvas_box_rect[:angle] += 2.0 if args.inputs.keyboard.a
  args.state.canvas_box_rect[:angle] -= 2.0 if args.inputs.keyboard.d
  args.state.gravity_arrow[:angle] = args.geometry.angle_to([box_cx, box_cy], args.inputs.mouse) + 90 if args.inputs.mouse.button_left

  # gravity application
  pen[:dx] += (gravity_strength * arrow_sin_a).clamp(-max_velocity, max_velocity)
  pen[:dy] -= (gravity_strength * arrow_cos_a).clamp(-max_velocity, max_velocity)
  
  pen[:x] += pen[:dx].clamp(-max_velocity, max_velocity)
  pen[:y] += pen[:dy].clamp(-max_velocity, max_velocity)

  # collision handling
  pen_cx = pen[:x] + pen[:w] * 0.5
  pen_cy = pen[:y] + pen[:h] * 0.5

  local_x = (pen_cx - box_cx) * cos_a + (pen_cy - box_cy) * sin_a
  local_y = -(pen_cx - box_cx) * sin_a + (pen_cy - box_cy) * cos_a
  local_dx = pen[:dx] * cos_a + pen[:dy] * sin_a
  local_dy = -pen[:dx] * sin_a + pen[:dy] * cos_a

  half_w = box[:w] * 0.5 - pen[:w] * 0.5
  half_h = box[:h] * 0.5 - pen[:h] * 0.5

  if local_x < -half_w
    local_x = -half_w
    local_dx = 0
  elsif local_x > half_w
    local_x = half_w
    local_dx = 0
  end

  if local_y < -half_h
    local_y = -half_h
    local_dy = 0
  elsif local_y > half_h
    local_y = half_h
    local_dy = 0
  end

  world_x = local_x * cos_a - local_y * sin_a + box_cx
  world_y = local_x * sin_a + local_y * cos_a + box_cy

  pen[:x] = world_x - pen[:w] * 0.5
  pen[:y] = world_y - pen[:h] * 0.5

  pen[:dx] = local_dx * cos_a - local_dy * sin_a
  pen[:dy] = local_dx * sin_a + local_dy * cos_a
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
    angle: args.state.canvas_box_rect[:angle],
    path: :canvas_box
  }

  args.outputs.sprites << args.state.gravity_arrow

  args.outputs.sprites << args.state.pen
end
