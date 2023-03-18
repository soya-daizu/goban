abstract struct Goban::AbstractQR
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

  module CanvasDrawer
    protected def draw_pattern(canvas : Matrix(UInt8), x : Int, y : Int, pattern, pattern_size : Int)
      pattern_size.times do |i|
        xx = x + i
        pattern_size.times do |j|
          yy = y + j
          canvas[xx, yy] = pattern[pattern_size * j + i]
        end
      end
    end

    protected def draw_timing_pattern(canvas : Matrix(UInt8), j : Int, count : Int)
      count.times do |k|
        i = 8 + k
        mod = i.even? ? 0xc1_u8 : 0xc0_u8
        canvas[i, j] = mod
        canvas[j, i] = mod
      end
    end
  end
end
