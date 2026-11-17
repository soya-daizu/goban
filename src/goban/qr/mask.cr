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
      FORMAT_BITS[@value][ecl.to_s]
    end

    # Evaluate penalty score for the given canvas.
    # It assumes that one of the masks is applied to the canvas.
    #
    # Each row and column is packed into bits (bit `i` holds the color of the
    # `i`-th module) and every rule is evaluated on whole lines at once with
    # bitwise operations instead of walking the modules one by one.
    # The number of 64-bit words per line is chosen by the symbol size.
    protected def self.evaluate_score(canvas : Canvas(UInt8))
      size = canvas.size
      if size <= 64
        self.evaluate_score(canvas, StaticArray(UInt64, 1))
      elsif size <= 128
        self.evaluate_score(canvas, StaticArray(UInt64, 2))
      elsif size <= 192
        self.evaluate_score(canvas, StaticArray(UInt64, 3))
      else
        raise InternalError.new("Canvas too large")
      end
    end

    private def self.evaluate_score(canvas : Canvas(UInt8), line_type : StaticArray(UInt64, W).class) forall W
      size = canvas.size
      data = canvas.data.to_unsafe
      # Positions that have a right/lower neighbor in the symbol
      pair_mask = self.low_bits(size - 1, line_type)

      adj_score, fin_score, blk_score, dark_count = 0, 0, 0, 0
      prev_row = self.pack_line(data, 1, size, line_type)
      size.times do |i|
        row = i == 0 ? prev_row : self.pack_line(data + i * size, 1, size, line_type)
        col = self.pack_line(data + i, size, size, line_type)

        adj_score += self.adjacent_score(row, pair_mask) + self.adjacent_score(col, pair_mask)
        fin_score += self.finder_score(row) + self.finder_score(col)
        dark_count += self.popcount(row)
        blk_score += self.block_score(prev_row, row, pair_mask) if i > 0

        prev_row = row
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

    # Packs `size` modules starting at `ptr` and spaced by `stride` into a line.
    # Bits beyond the symbol size are zero.
    @[AlwaysInline]
    private def self.pack_line(ptr : UInt8*, stride : Int32, size : Int32, line_type : StaticArray(UInt64, W).class) forall W
      StaticArray(UInt64, W).new do |k|
        word = 0_u64
        start = k * 64
        Math.min(size - start, 64).times do |b|
          word |= (ptr[(start + b) * stride] & 1).to_u64.unsafe_shl(b)
        end
        word
      end
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
