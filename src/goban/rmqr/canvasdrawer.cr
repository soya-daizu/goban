require "../abstract/canvasdrawer"

struct Goban::RMQR < Goban::AbstractQR
  # Handles painting each QR Code modules on a canvas.
  struct CanvasDrawer < AbstractQR::CanvasDrawer
    @mask : Mask
    @size : SymbolDimension

    # Creates a blank canvas with the given version and error correction level.
    def initialize(@version : Version, @ecl : ECC::Level)
      @size = @version.symbol_size
      @canvas = Matrix(UInt8).new(@size.width, @size.height, 0)
      @mask = Mask.new
    end

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - A finder pattern and a finder sub pattern on the top left and bottom right corner each
    # - Alignment patterns depending on the QR Code version
    # - Timing patterns in both directions
    protected def draw_function_patterns
      draw_pattern(0, 0, FINDER_PATTERN, 7)
      draw_pattern(@size.width - 5, @size.height - 5, FINDER_SUB_PATTERN, 5)

      @canvas[7, 0, 1, 7] = 0xc0
      @canvas[0, 7, 8, 1] = 0xc0 if @size.height > 7

      draw_timing_line(8, 0, @size.width - 11, true)
      if @size.height == 7
        draw_timing_line(8, @size.height - 1, @size.width - 13, true)
      else
        draw_timing_line(3, @size.height - 1, @size.width - 8, true)

        draw_timing_line(0, 8, @size.height - 11, false)
        draw_timing_line(@size.width - 1, 3, @size.height - 8, false)
      end

      @version.v_timing_lines_pos.each do |x|
        draw_timing_line(x, 0, @size.height, false)

        draw_pattern(x - 1, 0, RMQR_ALIGNMENT_PATTERN, 3)
        draw_pattern(x - 1, @size.height - 3, RMQR_ALIGNMENT_PATTERN, 3)
      end

      # Corner finder patterns
      canvas[@size.width - 1, 0, 1, 3] = 0xc1
      canvas[@size.width - 3, 0, 2, 1] = 0xc1
      canvas[0, @size.height - 3, 1, 3] = 0xc1 if @size.height > 9
      canvas[1, @size.height - 1, 2, 1] = 0xc1 if @size.height > 7

      canvas[@size.width - 2, 1] = 0xc0
      canvas[1, @size.height - 2] = 0xc0 if @size.height > 9

      draw_version_modules
    end

    # Draws data bits from the given data codewords.
    protected def draw_data_codewords(data_codewords : Slice(UInt8))
      data_length = data_codewords.size * 8

      i = 0
      upward = true            # Current filling direction
      base_x = @size.width - 2 # Zig zag filling starts from bottom right
      while base_x > 1
        (0...@size.height).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : @size.height - 1 - base_y
            next if @canvas[x, y] & 0x80 > 0
            return if i >= data_length

            bit = data_codewords[i >> 3].bit(7 - i & 7)
            @canvas[x, y] = bit
            i += 1
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    # Applies mask to the canvas.
    protected def apply_mask
      @mask.apply_to(@canvas)
    end

    private def draw_timing_line(x : Int, y : Int, count : Int, horizontal : Bool)
      return if count < 1
      count.times do |k|
        i = horizontal ? x + k : x
        j = horizontal ? y : y + k
        mod = (horizontal ? i : j).even? ? 0xc1_u8 : 0xc0_u8
        @canvas[i, j] = mod
      end
    end

    private def draw_version_modules
      data = @version.value.to_u32
      data |= 1 << 6 if @ecl.high?
      rem = data
      12.times do
        rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
      end
      bits_left = (data << 12 | rem) ^ 0b011111101010110010
      bits_right = (data << 12 | rem) ^ 0b100000101001111011

      (0...18).each do |i|
        bit = (bits_left >> i & 1).to_u8 | 0xc0
        x = 8 + i // 5
        y = 1 + i % 5
        @canvas[x, y] = bit

        bit = (bits_right >> i & 1).to_u8 | 0xc0
        if i < 15
          x = @size.width - 8 + i // 5
          y = @size.height - 6 + i % 5
        else
          x = @size.width + i - 20
          y = @size.height - 6
        end
        @canvas[x, y] = bit
      end
    end
  end
end
