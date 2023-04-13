struct Goban::RMQR < Goban::AbstractQR
  # Handles painting each QR Code modules on a canvas.
  module Template
    extend self
    include AbstractQR::Template

    # Creates a new matrix canvas with all the function patterns drawn for the given version.
    protected def make_canvas(version : Version, ecl : ECC::Level)
      size = version.symbol_size
      canvas = Matrix(UInt8).new(size.width, size.height, 0)
      self.draw_function_patterns(canvas, version, ecl)

      canvas
    end

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - A finder pattern and a finder sub pattern on the top left and bottom right corner each
    # - Alignment patterns depending on the QR Code version
    # - Timing patterns in both directions
    protected def draw_function_patterns(canvas : Matrix(UInt8), version : Version, ecl : ECC::Level)
      width, height = canvas.size_x, canvas.size_y

      self.draw_pattern(canvas, 0, 0, FINDER_PATTERN, 7)
      self.draw_pattern(canvas, width - 5, height - 5, FINDER_SUB_PATTERN, 5)

      canvas[7, 0, 1, 7] = 0xc0
      canvas[0, 7, 8, 1] = 0xc0 if height > 7

      self.draw_timing_line(canvas, 8, 0, width - 11, true)
      if height == 7
        self.draw_timing_line(canvas, 8, height - 1, width - 13, true)
      else
        self.draw_timing_line(canvas, 3, height - 1, width - 8, true)

        self.draw_timing_line(canvas, 0, 8, height - 11, false)
        self.draw_timing_line(canvas, width - 1, 3, height - 8, false)
      end

      version.v_timing_lines_pos.each do |x|
        self.draw_timing_line(canvas, x, 0, height, false)

        self.draw_pattern(canvas, x - 1, 0, RMQR_ALIGNMENT_PATTERN, 3)
        self.draw_pattern(canvas, x - 1, height - 3, RMQR_ALIGNMENT_PATTERN, 3)
      end

      # Corner finder patterns
      canvas[width - 1, 0, 1, 3] = 0xc1
      canvas[width - 3, 0, 2, 1] = 0xc1
      canvas[0, height - 3, 1, 3] = 0xc1 if height > 9
      canvas[1, height - 1, 2, 1] = 0xc1 if height > 7

      canvas[width - 2, 1] = 0xc0
      canvas[1, height - 2] = 0xc0 if height > 9

      self.draw_version_modules(canvas, version, ecl)
    end

    private def draw_timing_line(canvas : Matrix(UInt8), x : Int, y : Int, count : Int, horizontal : Bool)
      return if count < 1
      count.times do |k|
        i = horizontal ? x + k : x
        j = horizontal ? y : y + k
        mod = (horizontal ? i : j).even? ? 0xc1_u8 : 0xc0_u8
        canvas[i, j] = mod
      end
    end

    private def draw_version_modules(canvas : Matrix(UInt8), version : Version, ecl : ECC::Level)
      width, height = canvas.size_x, canvas.size_y
      bits_left, bits_right = version.get_version_bits(ecl)

      (0...18).each do |i|
        bit = (bits_left >> i & 1).to_u8 | 0xc0
        x = 8 + i // 5
        y = 1 + i % 5
        canvas[x, y] = bit

        bit = (bits_right >> i & 1).to_u8 | 0xc0
        if i < 15
          x = width - 8 + i // 5
          y = height - 6 + i % 5
        else
          x = width + i - 20
          y = height - 6
        end
        canvas[x, y] = bit
      end
    end
  end
end
