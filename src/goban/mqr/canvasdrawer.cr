require "../abstract/canvasdrawer"

struct Goban::MQR
  # Handles painting each Micro QR Code modules on a canvas.
  struct CanvasDrawer < AbstractQR::CanvasDrawer
    @mask : Mask
    @size : Int32

    # Creates a blank canvas with the given version and error correction level.
    def initialize(@version : Version, @ecl : ECC::Level)
      @size = @version.symbol_size
      @canvas = Canvas.new(@size)
      @mask = Mask.new(0) # Temporal value
    end

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - Finder patterns on the top left corner
    # - Timing patterns in both directions
    protected def draw_function_patterns
      @canvas.fill_module(0, 0, 9, 9, 0xc0)

      draw_pattern(0, 0, FINDER_PATTERN, 7)

      draw_timing_pattern(0, @size - 8)
    end

    # Draws data bits from the given data codewords.
    protected def draw_data_codewords(data_codewords : Slice(UInt8))
      data_length = data_codewords.size * 8

      i = 0
      upward = true      # Current filling direction
      base_x = @size - 1 # Zig zag filling starts from bottom right
      while base_x > 0
        (0...@size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : @size - 1 - base_y
            next if @canvas.get_module(x, y) & 0x80 > 0
            return if i >= data_length

            data_i = i >> 3
            if @version == 1 && data_i == 2 ||
               @version == 3 && @ecl.low? && data_i == 10 ||
               @version == 3 && @ecl.medium? && data_i == 8
              bit = data_codewords[data_i].bit(3 - i & 3)
              i += 1
              i += 4 if i % 4 == 0
            else
              bit = data_codewords[data_i].bit(7 - i & 7)
              i += 1
            end

            @canvas.set_module(x, y, bit)
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    # Test each mask patterns and apply one with the lowest (= best) score
    protected def apply_best_mask
      best_canvas = nil
      max_score = Int32::MIN

      4_u8.times do |i|
        canvas = @canvas.clone
        msk = Mask.new(i)
        msk.draw_format_modules(canvas, @version, @ecl)
        msk.apply_to(canvas)

        score = Mask.evaluate_score(canvas)
        if score > max_score
          @mask = msk
          best_canvas = canvas
          max_score = score
        end

        # puts i, score
        # canvas.print_to_console
      end
      raise "Unable to set the mask" unless best_canvas
      # puts @mask

      @canvas = best_canvas
      @mask
    end
  end
end
