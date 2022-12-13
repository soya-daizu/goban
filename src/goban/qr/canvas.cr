struct Goban::QR
  # Holds information about each modules in a QR Code symbol.
  struct Canvas
    # Returns the array of modules drawn on the canvas.
    getter modules : Array(Bool)
    # Length of the canvas's side.
    getter size : Int32
    # Returns the mask applied to the canvas.
    getter mask : Mask

    # Creates a blank canvas with the given version and error correction level.
    def initialize(@version : Version, @ecl : ECC::Level)
      @size = @version.symbol_size
      @modules = Array(Bool).new(@size ** 2, false)
      @reserved_modules = @modules.clone
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
      reserve_modules(0, 0, 9, 9)
      reserve_modules(@size - 8, 0, 8, 9)
      reserve_modules(0, @size - 8, 9, 8)

      positions = @version.alignment_pattern_positions
      ali_pat_count = positions.size
      ali_pat_count.times do |i|
        ali_pat_count.times do |j|
          next if i == 0 && j == 0 ||
                  i == 0 && j == ali_pat_count - 1 ||
                  i == ali_pat_count - 1 && j == 0
          x, y = positions[i], positions[j]

          draw_alignment_pattern(x, y)
          reserve_modules(x - 2, y - 2, 5, 5)
        end
      end

      tim_pat_mods_count = @version.timing_pattern_mods_count
      (8...8 + tim_pat_mods_count).each do |i|
        next unless i.even?
        set_module(i, 6)
        set_module(6, i)
      end
      reserve_modules(8, 6, tim_pat_mods_count, 1)
      reserve_modules(6, 8, 1, tim_pat_mods_count)

      version_modules_exist = draw_version_modules
      if version_modules_exist
        # Reserve version info area
        reserve_modules(@size - 11, 0, 3, 6)
        reserve_modules(0, @size - 11, 6, 3)
      end
    end

    # Draws data bits from the given data codewords.
    protected def draw_data_codewords(data_codewords : Array(UInt8))
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
            next if module_reserved?(x, y) || i >= data_length

            set_module(x, y, data_codewords[i >> 3].bit(7 - i & 7) == 1)
            i += 1
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    # Test each mask patterns and apply one with the lowest (= best) score
    protected def apply_best_mask
      mask = nil
      min_score = Int32::MAX

      8_u8.times do |i|
        msk = Mask.new(i)
        draw_format_modules(msk)
        msk.apply_to(self)

        score = Mask.evaluate_score(self)
        if score < min_score
          mask = msk
          min_score = score
        end

        msk.apply_to(self)
      end
      raise "Unable to set the mask" unless mask

      draw_format_modules(mask)
      mask.apply_to(self)
      @mask = mask
    end

    private def draw_finder_pattern(x : Int, y : Int)
      fill_module(x, y, 7)
      (y + 1..y + 5).each do |yy|
        set_module(x, yy)
        set_module(x + 6, yy)
        if (y + 2..y + 4).includes?(yy)
          fill_module(x + 2, yy, 3)
        end
      end
      fill_module(x, y + 6, 7)
    end

    private def draw_alignment_pattern(x : Int, y : Int)
      fill_module(x - 2, y - 2, 5)
      set_module(x, y)
      (y - 1..y + 1).each do |yy|
        set_module(x - 2, yy)
        set_module(x + 2, yy)
      end
      fill_module(x - 2, y + 2, 5)
    end

    private def draw_version_modules
      return false if @version < 7

      data = @version.value.to_u32
      rem = data
      12.times do
        rem = (rem << 1) ^ ((rem >> 11) * 0x1F25)
      end
      bits = data << 12 | rem

      (0...18).each do |i|
        bit = bits.bit(i) == 1
        x = i // 3
        y = @size - 11 + i % 3
        set_module(x, y, bit)
        set_module(y, x, bit)
      end

      true
    end

    private def draw_format_modules(mask : Mask)
      data = (@ecl.format_bits << 3 | mask.value).to_u32
      rem = data
      10.times do
        rem = (rem << 1) ^ ((rem >> 9) * 0x537)
      end
      bits = (data << 10 | rem) ^ 0x5412

      (0...8).each do |i|
        bit = bits.bit(i) == 1
        pos = i >= 6 ? i + 1 : i
        set_module(8, pos, bit)
        pos = @size - 1 - i
        set_module(pos, 8, bit)
      end

      (0...7).each do |i|
        bit = bits.bit(14 - i) == 1
        pos = i >= 6 ? i + 1 : i
        set_module(pos, 8, bit)
        pos = @size - 1 - i
        set_module(8, pos, bit)
      end

      set_module(8, @size - 8, true)
    end

    protected def set_module(x : Int, y : Int, value : Bool? = true)
      # We are absolutely sure that the index is within the bounds,
      # as the arrays are pre-allocated based on the given version
      # and all the set/get methods are called based on that size
      @modules.unsafe_put(y * @size + x, value)
    end

    protected def fill_module(x : Int, y : Int, w : Int, value : Bool? = true)
      @modules.fill(value, y * @size + x, w)
    end

    private def reserve_modules(x : Int, y : Int, w : Int, h : Int)
      (y...y + h).each do |yy|
        @reserved_modules.fill(true, yy * @size + x, w)
      end
    end

    # Returns whether a module at the given coordinate is dark or not.
    def get_module(x : Int, y : Int) : Bool
      @modules[y * @size + x]
    end

    # Returns whether a module at the given coordinate is reserved for
    # it being a part of function patterns.
    def module_reserved?(x : Int, y : Int)
      @reserved_modules[y * @size + x]
    end

    # Prints the modules on the canvas as a text in the console.
    def print_to_console
      @size.times do |y|
        @size.times do |x|
          print get_module(x, y) ? "██" : "  "
        end
        print '\n'
      end
      print '\n'
    end
  end
end
