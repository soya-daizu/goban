require "../abstract/canvasdrawer"

struct Goban::QR
  # Handles painting each QR Code modules on a canvas.
  struct CanvasDrawer < AbstractQR::CanvasDrawer
    @mask : Mask

    # Creates a blank canvas with the given version and error correction level.
    def initialize(@version : Version, @ecl : ECC::Level)
      @size = @version.symbol_size
      @canvas = Canvas.new(@size)
      @mask = Mask.new(0) # Temporal value
    end

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - Finder patterns on each corner except bottom right
    # - Alignment patterns depending on the QR Code version
    # - Timing patterns in both directions
    protected def draw_function_patterns
      draw_finder_pattern(0, 0)
      draw_finder_pattern(@size - 7, 0)
      draw_finder_pattern(0, @size - 7)

      # Reserving areas for the finder patterns and format info at once
      # as they belong to the same adjacent square area
      @canvas.fill_module(0, 7, 9, 2, 0xc0)
      @canvas.fill_module(7, 0, 2, 7, 0xc0)
      @canvas.fill_module(@size - 8, 0, 1, 7, 0xc0)
      @canvas.fill_module(@size - 8, 7, 8, 2, 0xc0)
      @canvas.fill_module(0, @size - 8, 8, 1, 0xc0)
      @canvas.fill_module(7, @size - 7, 2, 7, 0xc0)

      positions = @version.alignment_pattern_positions
      ali_pat_count = positions.size
      ali_pat_count.times do |i|
        ali_pat_count.times do |j|
          next if i == 0 && j == 0 ||
                  i == 0 && j == ali_pat_count - 1 ||
                  i == ali_pat_count - 1 && j == 0
          x, y = positions[i], positions[j]

          draw_alignment_pattern(x - 2, y - 2)
        end
      end

      draw_timing_pattern_modules(6, @size - 16)

      draw_version_modules

      canvas.set_module(8, canvas.size - 8, 0xc1)
    end

    # Draws data bits from the given data codewords.
    protected def draw_data_codewords(data_codewords : Slice(UInt8))
      data_length = data_codewords.size * 8

      i = 0
      upward = true      # Current filling direction
      base_x = @size - 1 # Zig zag filling starts from bottom right
      while base_x > 0
        base_x = 5 if base_x == 6 # Skip vertical timing pattern

        (0...@size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : @size - 1 - base_y
            next if @canvas.get_module(x, y) & 0x80 > 0
            return if i >= data_length

            bit = data_codewords[i >> 3].bit(7 - i & 7)
            @canvas.set_module(x, y, bit)
            i += 1
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    # Test each mask patterns and apply one with the lowest (= best) score
    protected def apply_best_mask
      best_canvas = nil
      min_score = Int32::MAX

      8_u8.times do |i|
        canvas = @canvas.clone
        msk = Mask.new(i)
        msk.draw_format_modules(canvas, @ecl)
        msk.apply_to(canvas)

        score = Mask.evaluate_score(canvas)
        if score < min_score
          @mask = msk
          best_canvas = canvas
          min_score = score
        end

        # puts i, score
        # canvas.print_to_console
      end
      raise "Unable to set the mask" unless best_canvas
      # puts @mask

      @canvas = best_canvas
      @mask
    end

    private def draw_version_modules
      return if @version < 7

      data = @version.value.to_u32
      rem = data
      12.times do
        rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
      end
      bits = data << 12 | rem

      (0...18).each do |i|
        bit = (bits >> i & 1).to_u8 | 0xc0
        x = i // 3
        y = @size - 11 + i % 3
        @canvas.set_module(x, y, bit)
        @canvas.set_module(y, x, bit)
      end
    end
  end
end
