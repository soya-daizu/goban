struct Goban::QRCode
  struct Canvas
    getter modules : Array(Array(Bool))

    def initialize(@version : Version, @ecl : ECLevel)
      @modules = Array(Array(Bool)).new(@version.symbol_size) do
        Array(Bool).new(@version.symbol_size, false)
      end
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
        @modules[i][6] = true
        @modules[6][i] = true
      end
      reserve_modules(8, 6, tim_pat_mods_count, 1)
      reserve_modules(6, 8, 1, tim_pat_mods_count)

      if draw_version_modules
        # Reserve version info area
        reserve_modules(size - 11, 0, 3, 6)
        reserve_modules(0, size - 11, 6, 3)
      end
    end

    private def draw_finder_pattern(x : Int, y : Int)
      @modules[y].fill(true, x, 7)
      (y + 1..y + 5).each do |yy|
        @modules[yy][x] = true
        @modules[yy][x + 6] = true
        if (y + 2..y + 4).includes?(yy)
          @modules[yy].fill(true, x + 2, 3)
        end
      end
      @modules[y + 6].fill(true, x, 7)
    end

    private def draw_alignment_pattern(x : Int, y : Int)
      @modules[y - 2].fill(true, x - 2, 5)
      @modules[y][x] = true
      (y - 1..y + 1).each do |yy|
        @modules[yy][x - 2] = true
        @modules[yy][x + 2] = true
      end
      @modules[y + 2].fill(true, x - 2, 5)
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
        y = @modules.size - 11 + i % 3
        @modules[y][x] = bit
        @modules[x][y] = bit
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
        @modules[pos][8] = bit
        pos = @modules.size - 1 - i
        @modules[8][pos] = bit
      end

      (0...7).each do |i|
        bit = bits.bit(14 - i) == 1
        pos = i >= 6 ? i + 1 : i
        @modules[8][pos] = bit
        pos = @modules.size - 1 - i
        @modules[pos][8] = bit
      end

      @modules[@modules.size - 8][8] = true
    end

    private def reserve_modules(x : Int, y : Int, w : Int, h : Int)
      (y...y + h).each do |i|
        (x...x + w).each do |j|
          @reserved_modules[i][j] = true
        end
      end
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
            if !@reserved_modules[y][x] && i < data_codewords.size * 8
              @modules[y][x] = data_codewords[i >> 3].bit(7 - i & 7) == 1
              i += 1
            end
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    def apply_best_mask
      mask = nil
      min_score = Int32::MAX
      8_u8.times do |i|
        msk = Mask.new(i)
        draw_format_modules(msk)
        msk.apply_to(@modules, @reserved_modules)
        score = Mask.evaluate_score(@modules)
        puts i
        puts score
        if score < min_score
          mask = msk
          min_score = score
        end
        msk.apply_to(@modules, @reserved_modules)
      end
      raise "Unable to set the mask" unless mask
      draw_format_modules(mask)
      mask.apply_to(@modules, @reserved_modules)
    end

    def print_to_console
      border = 4
      @modules.size.times do |y|
        @modules.size.times do |x|
          print @modules[y][x] ? "██" : "  "
        end
        print '\n'
      end
      print '\n'
    end
  end
end
