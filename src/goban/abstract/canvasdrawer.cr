module Goban::AbstractQR
  abstract struct CanvasDrawer
    # Canvas that holds color of each modules.
    getter canvas : Canvas
    # Length of the canvas's side.
    getter size
    # Returns the mask applied to the canvas.
    getter mask

    protected def initialize(@canvas, @size, @mask)
    end

    FINDER_PATTERN = {
      0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8,
    }

    FINDER_SUB_PATTERN = {
      0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc1_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8,
    }

    ALIGNMENT_PATTERN = FINDER_SUB_PATTERN

    RMQR_ALIGNMENT_PATTERN = {
      0xc1_u8, 0xc1_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc1_u8, 0xc1_u8,
    }

    private def draw_pattern(x : Int, y : Int, pattern, pattern_size : Int)
      pattern_size.times do |i|
        xx = x + i
        pattern_size.times do |j|
          yy = y + j
          @canvas.set_module(xx, yy, pattern[pattern_size * j + i])
        end
      end
    end

    private def draw_timing_pattern(j : Int, count : Int)
      count.times do |k|
        i = 8 + k
        mod = i.even? ? 0xc1_u8 : 0xc0_u8
        @canvas.set_module(i, j, mod)
        @canvas.set_module(j, i, mod)
      end
    end
  end
end
