module Goban::AbstractQR
  abstract struct CanvasDrawer
    # Canvas that holds color of each modules.
    getter canvas : Canvas
    # Length of the canvas's side.
    getter size : Int32
    # Returns the mask applied to the canvas.
    getter mask : Mask

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

    private def draw_finder_pattern(x : Int, y : Int)
      7.times do |i|
        xx = x + i
        7.times do |j|
          yy = y + j
          @canvas.set_module(xx, yy, FINDER_PATTERN[7 * j + i])
        end
      end
    end

    ALIGNMENT_PATTERN = {
      0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc1_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc0_u8, 0xc0_u8, 0xc0_u8, 0xc1_u8,
      0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8, 0xc1_u8,
    }

    private def draw_alignment_pattern(x : Int, y : Int)
      5.times do |i|
        xx = x + i
        5.times do |j|
          yy = y + j
          @canvas.set_module(xx, yy, ALIGNMENT_PATTERN[5 * j + i])
        end
      end
    end

    private def draw_timing_pattern_modules(j : Int, count : Int)
      count.times do |k|
        i = 8 + k
        mod = i.even? ? 0xc1_u8 : 0xc0_u8
        @canvas.set_module(i, j, mod)
        @canvas.set_module(j, i, mod)
      end
    end
  end
end
