struct Goban::QR < Goban::AbstractQR
  # Represents a mask pattern that can be applied to a canvas.
  struct Mask < AbstractQR::Mask
    MIN = 0_u8
    MAX = 7_u8

    MASK_PATTERNS = {
      ->(x : Int32, y : Int32) { (x + y) & 1 == 0 },
      ->(x : Int32, y : Int32) { y & 1 == 0 },
      ->(x : Int32, y : Int32) { x % 3 == 0 },
      ->(x : Int32, y : Int32) { (x + y) % 3 == 0 },
      ->(x : Int32, y : Int32) { (x // 3 + y // 2) & 1 == 0 },
      ->(x : Int32, y : Int32) { ((x * y) & 1) + (x * y) % 3 == 0 },
      ->(x : Int32, y : Int32) { (((x * y) & 1) + (x * y) % 3) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x + y) & 1) + (x * y) % 3) & 1 == 0 },
    }

    {% begin %}
      FORMAT_BITS = {
        {% for mask in (MIN..MAX) %}
          {
            {% for ecl in ECC::Level.constants %}
              {% ecl_value = ECC::Level.constant(ecl) %}
              {% data = 0_i32 + ecl_value << 3 | mask %}
              {% rem = data %}
              {% for _ in (0..9) %}
                {% rem = (rem << 1) ^ ((rem >> 9) * 0x537) %}
              {% end %}
              {% bits = (data << 10 | rem) ^ 0x5412 %}

              {{ecl.id}}: {{bits}},
            {% end %}
          },
        {% end %}
      }
    {% end %}

    def initialize(value)
      raise InputError.new("Invalid mask number") unless value.in?(MIN..MAX)
      @value = value.to_u8
      @mask_pattern = MASK_PATTERNS[@value]
    end

    protected def get_format_bits(ecl : ECC::Level)
      ECC.lookup(FORMAT_BITS[@value], ecl)
    end

    # The largest symbol size (version 40). Lines are packed into up to
    # 3 words (192 bits), which also covers the light area after the symbol
    # that the finder-like pattern rule looks at.
    private MAX_SIZE = 177

    # Every mask pattern repeats every 6 modules horizontally and every
    # 12 modules vertically, so the patterns of 12 rows and 12 columns are
    # enough to cover any symbol. They are stored as packed lines: bit `i`
    # of `ROW_PATTERNS[mask][y % 12]` is set if the module at (i, y) is
    # inverted, and likewise `COL_PATTERNS[mask][x % 12]` for (x, i).
    private PATTERN_PERIOD = 12

    private ROW_PATTERNS = self.build_patterns(true)
    private COL_PATTERNS = self.build_patterns(false)

    private def self.build_patterns(is_row : Bool)
      StaticArray(StaticArray(StaticArray(UInt64, 3), PATTERN_PERIOD), 8).new do |mask|
        pattern = MASK_PATTERNS[mask]
        StaticArray(StaticArray(UInt64, 3), PATTERN_PERIOD).new do |j|
          StaticArray(UInt64, 3).new do |k|
            word = 0_u64
            64.times do |b|
              i = k * 64 + b
              inverted = is_row ? pattern.call(i, j) : pattern.call(j, i)
              word |= 1_u64 << b if inverted
            end
            word
          end
        end
      end
    end

    # Apply mask to the given canvas.
    # Call this method again to reverse the applied mask.
    protected def apply_to(canvas : Canvas(UInt8))
      size = canvas.size_x
      data = canvas.data
      canvas.size_y.times do |y|
        pattern = ROW_PATTERNS[@value][y % PATTERN_PERIOD]
        row = y * size
        size.times do |x|
          value = data.unsafe_fetch(row + x)
          invert = (pattern.unsafe_fetch(x >> 6) >> (x & 63)).to_u8! & 1
          # Function modules (flagged with 0x80) are left untouched
          data.unsafe_put(row + x, value ^ (invert & ~(value >> 7)))
        end
      end
    end

    # Applies the mask with the lowest penalty score to the canvas with the
    # codewords drawn but no mask and format information applied yet.
    # Returns the mask and a new canvas of the masked symbol with the format
    # information drawn, where each module is normalized to 0 (light) or 1 (dark).
    #
    # Instead of applying each mask to a copy of the canvas, the canvas is
    # packed into rows and columns of bits once, and each candidate is built
    # by XORing the packed mask patterns on the data modules and patching in
    # the format information bits. The resulting canvas is unpacked from the
    # rows of the chosen candidate.
    protected def self.apply_best(canvas : Canvas(UInt8), ecl : ECC::Level) : Tuple(Mask, Canvas(UInt8))
      size = canvas.size
      if size <= 64
        self.apply_best(canvas, ecl, StaticArray(UInt64, 1))
      elsif size <= 128
        self.apply_best(canvas, ecl, StaticArray(UInt64, 2))
      elsif size <= MAX_SIZE
        self.apply_best(canvas, ecl, StaticArray(UInt64, 3))
      else
        raise InternalError.new("Canvas too large")
      end
    end

    private def self.apply_best(canvas : Canvas(UInt8), ecl : ECC::Level, line_type : StaticArray(UInt64, W).class) forall W
      size = canvas.size
      data = canvas.data.to_unsafe

      # Colors of the unmasked modules, and which modules are data modules
      # (i.e. not function patterns) that the masks apply to
      base_rows = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      base_cols = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      data_rows = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      data_cols = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      size.times do |i|
        base_rows[i] = self.pack_line(data + i * size, 1, size, line_type) { |v| v & 1 }
        base_cols[i] = self.pack_line(data + i, size, size, line_type) { |v| v & 1 }
        data_rows[i] = self.pack_line(data + i * size, 1, size, line_type) { |v| (v >> 7) ^ 1 }
        data_cols[i] = self.pack_line(data + i, size, size, line_type) { |v| (v >> 7) ^ 1 }
      end

      lines = {
        pointerof(base_rows).as(StaticArray(UInt64, W)*),
        pointerof(base_cols).as(StaticArray(UInt64, W)*),
        pointerof(data_rows).as(StaticArray(UInt64, W)*),
        pointerof(data_cols).as(StaticArray(UInt64, W)*),
      }

      best_mask, min_score = 0_u8, Int32::MAX
      {% if flag?(:preview_mt) %}
        channel = Channel(Tuple(UInt8, Int32)).new(8)
        8_u8.times do |mask|
          spawn do
            channel.send({mask, self.masked_score(mask, ecl, size, *lines)})
          end
        end
        8.times do
          mask, score = channel.receive
          # Prefer the lower mask number on ties, as in the sequential version
          if score < min_score || score == min_score && mask < best_mask
            best_mask, min_score = mask, score
          end
        end
      {% else %}
        8_u8.times do |mask|
          score = self.masked_score(mask, ecl, size, *lines)
          best_mask, min_score = mask, score if score < min_score
        end
      {% end %}

      rows = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      self.build_masked_lines(best_mask, ecl, size, lines[0], lines[2], pointerof(rows).as(StaticArray(UInt64, W)*), true)

      result = Canvas(UInt8).new(size, size, 0_u8)
      result_data = result.data
      size.times do |y|
        row = rows[y]
        size.times do |x|
          result_data.unsafe_put(y * size + x, row.unsafe_fetch(x >> 6).unsafe_shr(x & 63).to_u8! & 1)
        end
      end

      {Mask.new(best_mask), result}
    end

    # Penalty score of the canvas (given as packed lines) with the mask and
    # the matching format information applied.
    private def self.masked_score(mask : UInt8, ecl : ECC::Level, size : Int32,
                                  base_rows : StaticArray(UInt64, W)*, base_cols : StaticArray(UInt64, W)*,
                                  data_rows : StaticArray(UInt64, W)*, data_cols : StaticArray(UInt64, W)*) forall W
      rows = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      cols = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      rows_ptr = pointerof(rows).as(StaticArray(UInt64, W)*)
      cols_ptr = pointerof(cols).as(StaticArray(UInt64, W)*)
      self.build_masked_lines(mask, ecl, size, base_rows, data_rows, rows_ptr, true)
      self.build_masked_lines(mask, ecl, size, base_cols, data_cols, cols_ptr, false)

      self.evaluate_score(rows_ptr, cols_ptr, size)
    end

    # Writes the rows (or columns if `is_row` is false) of the canvas with the
    # mask and the matching format information applied to `result`.
    private def self.build_masked_lines(mask : UInt8, ecl : ECC::Level, size : Int32,
                                        base : StaticArray(UInt64, W)*, data : StaticArray(UInt64, W)*,
                                        result : StaticArray(UInt64, W)*, is_row : Bool) forall W
      patterns = (is_row ? ROW_PATTERNS : COL_PATTERNS).to_unsafe[mask]
      size.times do |i|
        pattern = self.truncate(patterns.unsafe_fetch(i % PATTERN_PERIOD), StaticArray(UInt64, W))
        result[i] = self.xor(base[i], self.and(pattern, data[i]))
      end

      Template.each_format_module(size, Mask.new(mask), ecl) do |x, y, bit|
        if is_row
          self.put_bit(result + y, x, bit)
        else
          self.put_bit(result + x, y, bit)
        end
      end
    end

    # Evaluate penalty score for the given canvas.
    # It assumes that one of the masks is applied to the canvas.
    protected def self.evaluate_score(canvas : Canvas(UInt8))
      size = canvas.size
      if size <= 64
        self.evaluate_score(canvas, StaticArray(UInt64, 1))
      elsif size <= 128
        self.evaluate_score(canvas, StaticArray(UInt64, 2))
      elsif size <= MAX_SIZE
        self.evaluate_score(canvas, StaticArray(UInt64, 3))
      else
        raise InternalError.new("Canvas too large")
      end
    end

    private def self.evaluate_score(canvas : Canvas(UInt8), line_type : StaticArray(UInt64, W).class) forall W
      size = canvas.size
      data = canvas.data.to_unsafe
      rows = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      cols = uninitialized StaticArray(StaticArray(UInt64, W), MAX_SIZE)
      size.times do |i|
        rows[i] = self.pack_line(data + i * size, 1, size, line_type) { |v| v & 1 }
        cols[i] = self.pack_line(data + i, size, size, line_type) { |v| v & 1 }
      end

      self.evaluate_score(pointerof(rows).as(StaticArray(UInt64, W)*), pointerof(cols).as(StaticArray(UInt64, W)*), size)
    end

    # Evaluate penalty score for the canvas given as its rows and columns
    # packed into bits (bit `i` holds the color of the `i`-th module).
    # Every rule is evaluated on whole lines at once with bitwise operations
    # instead of walking the modules one by one.
    private def self.evaluate_score(rows : StaticArray(UInt64, W)*, cols : StaticArray(UInt64, W)*, size : Int32) forall W
      # Positions that have a right/lower neighbor in the symbol
      pair_mask = self.low_bits(size - 1, StaticArray(UInt64, W))

      adj_score, fin_score, blk_score, dark_count = 0, 0, 0, 0
      size.times do |i|
        row, col = rows[i], cols[i]

        adj_score += self.adjacent_score(row, pair_mask) + self.adjacent_score(col, pair_mask)
        fin_score += self.finder_score(row) + self.finder_score(col)
        dark_count += self.popcount(row)
        blk_score += self.block_score(rows[i - 1], row, pair_mask) if i > 0
      end

      adj_score + fin_score + blk_score + self.compute_balance_score(dark_count, size)
    end

    # Adjacent modules in a line with the same color (N1):
    # each run of 5 + k modules scores 3 + k.
    @[AlwaysInline]
    private def self.adjacent_score(line : StaticArray(UInt64, W), pair_mask : StaticArray(UInt64, W)) forall W
      # Bit i: module i has the same color as module i + 1
      same = self.and(self.not(self.xor(line, self.shr(line, 1))), pair_mask)
      # Bit i: modules i..i + 4 all have the same color.
      # A run of length L >= 5 sets exactly L - 4 of these bits in a row.
      run5 = self.and(self.and(same, self.shr(same, 1)), self.and(self.shr(same, 2), self.shr(same, 3)))
      # First bit of each such group, i.e. one per run
      run_starts = self.and(run5, self.not(self.shl(run5, 1)))

      self.popcount(run5) + self.popcount(run_starts) * 2
    end

    # 2x2 blocks of modules with the same color (N2): 3 points each.
    @[AlwaysInline]
    private def self.block_score(upper : StaticArray(UInt64, W), lower : StaticArray(UInt64, W), pair_mask : StaticArray(UInt64, W)) forall W
      upper_same = self.not(self.xor(upper, self.shr(upper, 1)))
      lower_same = self.not(self.xor(lower, self.shr(lower, 1)))
      vertical_same = self.not(self.xor(upper, lower))
      blocks = self.and(self.and(upper_same, lower_same), self.and(vertical_same, pair_mask))

      self.popcount(blocks) * 3
    end

    # 1:1:3:1:1 finder-like patterns preceded or followed by 4 light modules (N3):
    # 40 points each. The area outside the symbol counts as light.
    @[AlwaysInline]
    private def self.finder_score(line : StaticArray(UInt64, W)) forall W
      dark = line
      # Bits beyond the symbol size are set here, and the shifts below fill in
      # ones, so the area outside the symbol is light on both sides
      light = self.not(line)

      # Bit i: modules i..i + 6 are dark-light-dark-dark-dark-light-dark
      core = self.and(
        self.and(self.and(dark, self.shr(light, 1, true)), self.and(self.shr(dark, 2), self.shr(dark, 3))),
        self.and(self.and(self.shr(dark, 4), self.shr(light, 5, true)), self.shr(dark, 6)),
      )
      # Bit i: modules i - 4..i - 1 are light
      light_before = self.and(
        self.and(self.shl(light, 1, true), self.shl(light, 2, true)),
        self.and(self.shl(light, 3, true), self.shl(light, 4, true)),
      )
      # Bit i: modules i + 7..i + 10 are light
      light_after = self.and(
        self.and(self.shr(light, 7, true), self.shr(light, 8, true)),
        self.and(self.shr(light, 9, true), self.shr(light, 10, true)),
      )

      (self.popcount(self.and(core, light_before)) + self.popcount(self.and(core, light_after))) * 40
    end

    # Packs `size` modules starting at `ptr` and spaced by `stride` into a line,
    # mapping each module to a bit (0 or 1) with the block.
    # Bits beyond the symbol size are zero.
    @[AlwaysInline]
    private def self.pack_line(ptr : UInt8*, stride : Int32, size : Int32, line_type : StaticArray(UInt64, W).class, &) forall W
      StaticArray(UInt64, W).new do |k|
        word = 0_u64
        start = k * 64
        Math.min(size - start, 64).times do |b|
          word |= (yield ptr[(start + b) * stride]).to_u64.unsafe_shl(b)
        end
        word
      end
    end

    # Sets bit `index` of the line to `bit` (0 or 1).
    @[AlwaysInline]
    private def self.put_bit(line : StaticArray(UInt64, W)*, index : Int32, bit : UInt8) forall W
      word = line.value.to_unsafe + (index >> 6)
      shift = index & 63
      word.value = (word.value & ~(1_u64 << shift)) | (bit.to_u64 << shift)
    end

    # First `W` words of a 3-word line.
    @[AlwaysInline]
    private def self.truncate(line : StaticArray(UInt64, 3), line_type : StaticArray(UInt64, W).class) forall W
      StaticArray(UInt64, W).new { |k| line[k] }
    end

    # Line with bits 0...count set.
    private def self.low_bits(count : Int32, line_type : StaticArray(UInt64, W).class) forall W
      StaticArray(UInt64, W).new do |k|
        bits = count - k * 64
        if bits >= 64
          UInt64::MAX
        elsif bits <= 0
          0_u64
        else
          (1_u64 << bits) - 1
        end
      end
    end

    # Bit i of the result is bit i + n of the line (0 < n < 64).
    # Vacated high bits are filled with ones if `fill` is true or zeros otherwise.
    @[AlwaysInline]
    private def self.shr(l : StaticArray(UInt64, W), n : Int32, fill = false) forall W
      StaticArray(UInt64, W).new do |k|
        upper = k + 1 < W ? l[k + 1] : (fill ? UInt64::MAX : 0_u64)
        l[k].unsafe_shr(n) | upper.unsafe_shl(64 - n)
      end
    end

    # Bit i of the result is bit i - n of the line (0 < n < 64).
    # Vacated low bits are filled with ones if `fill` is true or zeros otherwise.
    @[AlwaysInline]
    private def self.shl(l : StaticArray(UInt64, W), n : Int32, fill = false) forall W
      StaticArray(UInt64, W).new do |k|
        lower = k > 0 ? l[k - 1] : (fill ? UInt64::MAX : 0_u64)
        l[k].unsafe_shl(n) | lower.unsafe_shr(64 - n)
      end
    end

    @[AlwaysInline]
    private def self.and(a : StaticArray(UInt64, W), b : StaticArray(UInt64, W)) forall W
      StaticArray(UInt64, W).new { |k| a[k] & b[k] }
    end

    @[AlwaysInline]
    private def self.xor(a : StaticArray(UInt64, W), b : StaticArray(UInt64, W)) forall W
      StaticArray(UInt64, W).new { |k| a[k] ^ b[k] }
    end

    @[AlwaysInline]
    private def self.not(a : StaticArray(UInt64, W)) forall W
      StaticArray(UInt64, W).new { |k| ~a[k] }
    end

    @[AlwaysInline]
    private def self.popcount(a : StaticArray(UInt64, W)) forall W
      result = 0
      W.times { |k| result += a[k].popcount.to_i32 }
      result
    end

    private def self.compute_balance_score(dark_count : Int, size : Int)
      total_modules = size ** 2
      # k = floor(|dark ratio (%) - 50| / 5), computed in integers to avoid rounding errors
      k = (dark_count * 2 - total_modules).abs * 10 // total_modules
      k * 10
    end
  end
end
