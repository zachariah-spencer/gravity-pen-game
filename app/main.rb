FONT_PATH = "fonts/bondoni.ttf"

def tick args
  defaults args
  calc args
  render args
end

def defaults args

  if Kernel.tick_count == 0
    args.audio[:bg_music] = { input: "sounds/bg_music.ogg", looping: true, gain: 0.2}
  end

  args.state.playing_tick ||= nil
  # states are :ready, :playing, :score
  args.state.game_status ||= :ready
  args.state.game_duration ||= 60.0
  args.state.timer ||= args.state.game_duration
  args.state.correct_squares ||= 0
  args.state.mistaken_squares ||= 0
  args.state.accuracy_percentage ||= 0
  args.state.total_possible_correct_squares ||= 0
  args.state.mistake_percentage ||= 0
  args.state.calculated_percentage ||= 0
  args.state.box_rotation_velocity ||= 0.0
  

  args.state.pen ||= {
    path: "sprites/chroma-noir-8x8/items.png",
    x: Grid.w / 2 - 16,
    y: Grid.h / 2 - 16,
    x_offset: 32,
    y_offset: 32,
    w: 32,
    h: 32,
    tile_x: 8 * 2,
    tile_y: 1,
    tile_w: 7,
    tile_h: 7,
    angle: 180.0,
    dx: 0.0,
    dy: 0.0,
    drawing: false,
  }

  args.state.highlighted_pixels ||= []

  args.state.rune_pixels ||= []
  args.state.canvas_pixels ||= []
  
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
      # handle calc logic
      if !args.state.canvas_pixels[row_index][column_index]
        args.state.canvas_pixels[row_index] << {
            x: (256) + column_index * 32,
            y: (256 + 512 - 32) - row_index * 32,
            w: 32,
            h: 32,
            needed: false,
            drawn: false,
        }
      end

      current_pixel_index = args.state.canvas_pixels[row_index][column_index]
      current_pixel_index[:needed] = pixel
    

      # handle render
      if current_pixel_index[:drawn] && current_pixel_index[:needed]
        args.outputs[:canvas_box].primitives << {
          x: (256) + column_index * 32,
          y: (256 + 512 - 32) - row_index * 32,
          w: 32,
          h: 32,
          r: 0,
          g: 255,
          b: 255,
          a: 255,
          primitive_marker: :solid
        }
      elsif current_pixel_index[:drawn]
        args.outputs[:canvas_box].primitives << {
          x: (256) + column_index * 32,
          y: (256 + 512 - 32) - row_index * 32,
          w: 32,
          h: 32,
          r: 0,
          g: 5,
          b: 20,
          a: 255,
          primitive_marker: :solid
        }
      elsif current_pixel_index[:needed]
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
      else
        args.outputs[:canvas_box].primitives << {
          x: (256) + column_index * 32,
          y: (256 + 512 - 32) - row_index * 32,
          w: 32,
          h: 32,
          r: 13,
          g: 13,
          b: 13,
          a: 255,
          primitive_marker: :solid
        }
      end

      if args.state.highlighted_pixels.include?([row_index, column_index])
        args.outputs[:canvas_box].primitives << {
          x: (256) + column_index * 32,
          y: (256 + 512 - 32) - row_index * 32,
          w: 32,
          h: 32,
          r: 255,
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

  args.state.gravity_target_angle ||= args.state.gravity_arrow[:angle]
end

def reset_game args
  args.audio[:bell] = { input: "sounds/bell.wav", gain: 0.2}
  args.state.box_rotation_velocity = Numeric.rand(-1.2..1.2)
  args.state.game_status = :playing
  nil_or_one = [nil, nil, 1, nil, nil, nil]
  args.state.rune_pixels.clear
  args.state.canvas_pixels.clear
  16.times { args.state.rune_pixels << [] }
  16.times { args.state.canvas_pixels << [] }
  args.state.canvas_box_rect[:angle] = 0
  args.state.rune_pixels.each { |row| 16.times { row << nil_or_one.sample }}
  args.state.playing_tick = Kernel.tick_count
end

def calc args

  if args.state.playing_tick
    args.state.timer = args.state.game_duration - args.state.playing_tick.elapsed_time / 60
  end

  if args.state.timer <= 0.0 && args.state.playing_tick
    args.audio.delete(:drawing) if args.audio[:drawing]
    args.audio[:bell] = { input: "sounds/bell.wav", gain: 0.2, pitch: 0.7}
    args.state.game_status = :score
    args.state.timer = args.state.game_duration
    args.state.playing_tick = nil

    total_possible_correct = 0
    correct = 0
    incorrect = 0
    args.state.canvas_pixels.flatten.each do |pixel|
      total_possible_correct += 1 if pixel[:needed]
      correct += 1 if pixel[:needed] && pixel[:drawn]
      incorrect += 1 if !pixel[:needed] && pixel[:drawn]
    end

    args.state.correct_squares = correct
    args.state.mistaken_squares = incorrect
    args.state.total_possible_correct_squares = total_possible_correct
    puts args.state.total_possible_correct_squares
    args.state.accuracy_percentage = ((correct / total_possible_correct) * 100).round(1)
    args.state.mistake_percentage = ((incorrect / 256) * 100).round(1)
    args.state.calculated_percentage = args.state.accuracy_percentage - args.state.mistake_percentage
  end

  if args.inputs.mouse.click && !args.state.playing_tick 
    if args.state.game_status == :ready
      reset_game args
    elsif args.state.game_status == :score
      args.audio[:click] = { input: "sounds/select.wav", gain: 0.3}
      args.state.game_status = :ready
    end
  end
  return unless args.state.playing_tick

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

  gravity_strength = 0.5
  max_velocity = 2.5

  # box rotation
  box[:angle] += args.state.box_rotation_velocity

  # inputs
  # args.state.canvas_box_rect[:angle] += 2.0 if args.inputs.keyboard.a
  # args.state.canvas_box_rect[:angle] -= 2.0 if args.inputs.keyboard.d
  args.state.gravity_target_angle = args.geometry.angle_to([box_cx, box_cy], args.inputs.mouse) + 90 if args.inputs.mouse.button_left
  display_angle = lerp_angle(arrow[:angle], args.state.gravity_target_angle, 0.15)
  arrow[:angle] = display_angle
  pen[:drawing] = args.inputs.keyboard.space
  args.state.pen[:r] = args.state.pen[:drawing] ? 0 : 255
  args.state.pen[:g] = args.state.pen[:drawing] ? 0 : 255

  physics_rad = args.state.gravity_target_angle * Math::PI / 180.0
  pen[:dx] += gravity_strength * Math.sin(physics_rad)
  pen[:dy] -= gravity_strength * Math.cos(physics_rad)

  # damping
  damping = 0.94
  pen[:dx] *= damping
  pen[:dy] *= damping

  # gravity application
  # pen[:dx] += (gravity_strength * arrow_sin_a).clamp(-max_velocity, max_velocity)
  # pen[:dy] -= (gravity_strength * arrow_cos_a).clamp(-max_velocity, max_velocity)
  
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

  
  cell_size = 32
  half_w    = box[:w] * 0.5
  half_h    = box[:h] * 0.5

  row_count = args.state.canvas_pixels.length
  col_count = args.state.canvas_pixels.first.length

  center_col = ((local_x + half_w) / cell_size).floor.clamp(0, col_count - 1)
  center_row = ((half_h - local_y) / cell_size).floor.clamp(0, row_count - 1)

  args.state.highlighted_pixels.clear
  args.state.highlighted_pixels << [center_row, center_col]

  if args.inputs.keyboard.key_down.space
    args.audio[:draw] = { input: "sounds/scribble.wav", gain: 0.2 } 
    args.audio[:drawing] = { input: "sounds/drawing.ogg", gain: 0.8, looping: true }
  end
  if args.inputs.keyboard.key_up.space
    args.audio[:lift_pen] = { input: "sounds/scribble.wav", gain: 0.2, pitch: 0.9 } 
    args.audio.delete(:drawing)
  end
  

  return unless pen[:drawing]
  
  args.state.canvas_pixels[center_row][center_col][:drawn] = true
end

def lerp_angle(current, target, ratio)
  delta = ((target - current + 540) % 360) - 180
  current + delta * ratio
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

  args.state.gravity_arrow[:a] = 255
  args.outputs.sprites << args.state.gravity_arrow
  args.outputs.sprites << args.state.pen.merge({
    x: args.state.pen[:x] + args.state.pen[:x_offset],
    y: args.state.pen[:y] + args.state.pen[:y_offset],
  })

  args.outputs.primitives << {
    primitive_marker: :label,
    font: FONT_PATH,
    x: Grid.w / 2,
    y: Grid.h - 40,
    alignment_enum: 1,
    size_px: 30,
    text: "Time Left: #{'%.1f' % args.state.timer.round(1)}",
    r: 217,
    g: 217,
    b: 217,
  }

  unless args.state.playing_tick
    args.outputs.sprites.map do |sprite|
      sprite[:a] = 50
    end

    args.outputs.labels.map { |label| label[:a] = 50 }

    if args.state.game_status == :ready
      render_instructions args
      args.outputs.primitives << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h / 2 + 25,
        alignment_enum: 1,
        size_px: 128,
        text: "CLICK TO PLAY",
        r: 217,
        g: 217,
        b: 217,
      }
    elsif args.state.game_status == :score
      args.outputs.labels << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h - 64,
        alignment_enum: 1,
        size_px: 128,
        text: "SCORE",
        r: 217,
        g: 217,
        b: 217,
      }

      args.outputs.labels << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h - 100 - (80 * 1),
        alignment_enum: 1,
        size_px: 64,
        text: "Completion Percentage",
        r: 217,
        g: 217,
        b: 217,
      }

      args.outputs.labels << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h - 100 - (80 * 2),
        alignment_enum: 1,
        size_px: 64,
        text: "%#{'%.1f' % args.state.accuracy_percentage} - %#{'%.1f' % args.state.mistake_percentage} = %#{'%.1f' % args.state.calculated_percentage}",
        r: 217,
        g: 217,
        b: 217,
      }

      args.outputs.labels << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h - 100 - (80 * 3),
        alignment_enum: 1,
        size_px: 64,
        text: "Correctly Painted Squares",
        r: 217,
        g: 217,
        b: 217,
      }

      args.outputs.labels << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h - 100 - (80 * 4),
        alignment_enum: 1,
        size_px: 64,
        text: "#{'%.1f' % args.state.correct_squares} / #{'%.1f' % args.state.total_possible_correct_squares} = %#{'%.1f' % args.state.accuracy_percentage}",
        r: 217,
        g: 217,
        b: 217,
      }

      args.outputs.labels << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h - 100 - (80 * 5),
        alignment_enum: 1,
        size_px: 64,
        text: "Mistakenly Painted Squares",
        r: 217,
        g: 217,
        b: 217,
      }

      args.outputs.labels << {
        font: FONT_PATH,
        x: Grid.w / 2,
        y: Grid.h - 100 - (80 * 6),
        alignment_enum: 1,
        size_px: 64,
        text: "#{'%.1f' % args.state.mistaken_squares} / 256 = %#{'%.1f' % args.state.mistake_percentage}",
        r: 217,
        g: 217,
        b: 217,
      }
    end
  end

  args.outputs.primitives << {
    x: 0,
    y: 0,
    w: 1280,
    h: 720,
    a: 255 - Kernel.tick_count * 5,
    r: 0,
    g: 0,
    b: 0,
    primitive_marker: :solid
  }
end

def render_instructions args
  args.outputs.primitives << {
    primitive_marker: :label,
    font: FONT_PATH,
    x: Grid.w / 2,
    y: 120,
    alignment_enum: 1,
    size_px: 24,
    text: "Click and drag your MOUSE on the screen to change the flow of gravity.",
    r: 217,
    g: 217,
    b: 217,
  }

  args.outputs.primitives << {
    primitive_marker: :label,
    font: FONT_PATH,
    x: Grid.w / 2,
    y: 80,
    alignment_enum: 1,
    size_px: 24,
    text: "Press the SPACE BAR to draw with your pen on the canvas.",
    r: 217,
    g: 217,
    b: 217,
  }

  args.outputs.primitives << {
    primitive_marker: :label,
    font: FONT_PATH,
    x: Grid.w / 2,
    y: 40,
    alignment_enum: 1,
    size_px: 24,
    text: "Try to draw the magical rune by filling in the neon blue parts of the canvas.",
    r: 217,
    g: 217,
    b: 217,
  }
end