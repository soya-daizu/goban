struct Goban::QRCode
  struct Canvas
    getter modules : Array(Bool)
    getter size : Int32

    def initialize(@version : Version, @ecl : ECLevel)
      @size = @version.symbol_size
      @modules = Array(Bool).new(@size ** 2, false)
      @reserved_modules = @modules.clone
    end

    def draw_function_patterns
      size = @version.symbol_size

      draw_finder_pattern(0, 0)
      draw_finder_pattern(size - 7, 0)
      draw_finder_pattern(0, size - 7)

      # Reserve finder pattern and format info area at once
      # as they belong to the same adjacent square area
      reserve_modules(0, 0, 9, 9)
      reserve_modules(size - 8, 0, 8, 9)
      reserve_modules(0, size - 8, 9, 8)

      ali_pat_pos = alignment_pattern_positions
      ali_pat_count = ali_pat_pos.size
      ali_pat_count.times do |i|
        ali_pat_count.times do |j|
          next if i == 0 && j == 0 ||
                  i == 0 && j == ali_pat_count - 1 ||
                  i == ali_pat_count - 1 && j == 0
          x, y = ali_pat_pos[i], ali_pat_pos[j]

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

      if draw_version_modules
        # Reserve version info area
        reserve_modules(size - 11, 0, 3, 6)
        reserve_modules(0, size - 11, 6, 3)
      end
    end

    def draw_data_codewords(data_codewords : Array(UInt8))
      size = @version.symbol_size

      i = 0
      upward = true
      base_x = size - 1
      while base_x > 0
        base_x = 5 if base_x == 6 # Skip vertical timing pattern

        (0...size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : size - 1 - base_y
            # next if is_module_reserved(x, y) || i >= data_codewords.size * 8
            if !is_module_reserved?(x, y) && i < data_codewords.size * 8
              set_module(x, y, data_codewords[i >> 3].bit(7 - i & 7) == 1)
              i += 1
            end
          end
        end

        upward = !upward
        base_x -= 2
      end
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
      return if @version < 7

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

    private def alignment_pattern_positions
      v = @version.value
      return [] of Int32 if v == 1

      g = v // 7 + 2
      step = v == 32 ? 26 : (v * 4 + g * 2 + 1) // (g * 2 - 2) * 2
      result = (0...g - 1).map do |i|
        @version.symbol_size - 7 - i * step
      end
      result.push(6)
      result.reverse!

      result
    end

    protected def set_module(x : Int, y : Int, value : Bool? = true)
      @modules[y * @size + x] = value
    end

    protected def fill_module(x : Int, y : Int, w : Int, value : Bool? = true)
      @modules.fill(value, y * @size + x, w)
    end

    def get_module(x : Int, y : Int)
      @modules[y * @size + x]
    end

    private def reserve_module(x : Int, y : Int)
      @reserved_modules[y * @size + x] = true
    end

    private def reserve_modules(x : Int, y : Int, w : Int, h : Int)
      (y...y + h).each do |yy|
        (x...x + w).each do |xx|
          reserve_module(xx, yy)
        end
      end
    end

    def is_module_reserved?(x : Int, y : Int)
      @reserved_modules[y * @size + x]
    end

    def apply_best_mask
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
    end

    def print_to_console
      border = 4
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
