Maw!

controls.define :do_fn_each_send, keyboard: :space

init {
  $state.particle_system = ParticleSystem.new
  outputs.static_sprites << $state.particle_system
}

tick {
  if tick_count % 120 == 0
    current_time = Time.now
    diff_ticks = tick_count - $state.prev_ticks
    $state.current_fps = diff_ticks / (current_time - $state.prev_time) if $state.prev_time
    $state.prev_ticks = tick_count
    $state.prev_time = current_time
  end

  $state.particle_system.process_inputs args
}

def process_item i
  i.x = (i.x + i.vx) % 1280
  i.y = (i.y + i.vy) % 1280
  primitives << i
end

class ParticleSystem
  attr_accessor :should_fn_each_send
  def initialize
    @width = 5
    @particles = 1000.times.map do
      {
        x: rand(1280 - @width), y: rand(720 - @width),
        r: rand(50), g: rand(155), b: rand(155) + 100,
        vx: 3 * rand, vy: 3 * rand, blendmode_enum: rand(4) + 1
      }
    end

    @particles2 = 1000.times.map do
      {
        x: rand(1280 - @width), y: rand(720 - @width),
        r: rand(50), g: rand(155) + 100, b: rand(155),
        vx: 3 * rand, vy: 3 * rand, blendmode_enum: rand(4) + 1
      }
    end

    create_primitive_rts
  end

  
  def process_inputs args
    mouse = inputs.mouse
    @mouse_focus = mouse.has_focus
    @mouse_x = mouse.x + 200 * tick_count.sin
    @mouse_y = mouse.y + 200 * tick_count.sin
  end

  def process_particle i
    w = @width
    i.vy -= 0.1 if i.vy > -5
    if @mouse_focus
      dx = i.x - @mouse_x
      dy = i.y - @mouse_y
      dist_sq = dx * dx + dy * dy
      i.vx += (dx * Math::cos(dx / 100) + dy) * (dx + dy) / dist_sq
      i.vy += dy * dy * dy * dx / dist_sq / dist_sq
    end

    i.vy = i.vy.clamp(-5, 5)
    i.vx = (i.vx - i.vx / 10).clamp(-5, 5)
    i.x = (i.x + i.vx) % (1280 + w)
    i.y = (i.y + i.vy) % (720 + w)

    @ffi_draw.draw_sprite_4 i.x - w, i.y - w, w, w, "particle", nil,
                            nil, i.r, i.g, i.b,
                            nil, nil, nil, nil,
                            false, false,
                            0, 0,
                            nil, nil, nil, nil,
                            i.blendmode_enum
  end

  def draw_override ffi_draw
    @ffi_draw = ffi_draw

    fn.each_send @particles, self, :process_particle
    fn.each_send @particles2, self, :process_particle
  end
end


def create_primitive_rts
  white = { r: 255, g: 255, b: 255 }
  size = 10

  # circle
  outputs["particle"].w = size
  outputs["particle"].h = size
  size.times do |i|
    r = size / 2
    h = i - r
    l = Math::sqrt(r * r - h * h)
    outputs["particle"].lines << { x: i, y: r - l, x2: i, y2: r + l }.merge(white)
  end
end