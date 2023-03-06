require "../abstract/version"

struct Goban::RMQR < Goban::AbstractQR
  enum VersionValue : UInt8
    R7x43   = 0b00000
    R7x59   = 0b00001
    R7x77   = 0b00010
    R7x99   = 0b00011
    R7x139  = 0b00100
    R9x43   = 0b00101
    R9x59   = 0b00110
    R9x77   = 0b00111
    R9x99   = 0b01000
    R9x139  = 0b01001
    R11x27  = 0b01010
    R11x43  = 0b01011
    R11x59  = 0b01100
    R11x77  = 0b01101
    R11x99  = 0b01110
    R11x139 = 0b01111
    R13x27  = 0b10000
    R13x43  = 0b10001
    R13x59  = 0b10010
    R13x77  = 0b10011
    R13x99  = 0b10100
    R13x139 = 0b10101
    R15x43  = 0b10110
    R15x59  = 0b10111
    R15x77  = 0b11000
    R15x99  = 0b11001
    R15x139 = 0b11010
    R17x43  = 0b11011
    R17x59  = 0b11100
    R17x77  = 0b11101
    R17x99  = 0b11110
    R17x139 = 0b11111
  end

  struct SymbolDimension
    getter width : Int32
    getter height : Int32
    protected getter w_group : Int32
    protected getter h_group : Int32

    WIDTHS  = {27, 43, 59, 77, 99, 139}
    HEIGHTS = {7, 9, 11, 13, 15, 17}

    def initialize(version_value : VersionValue)
      v = version_value.to_i
      case v
      when 0..9
        @w_group = v % 5 + 1
        @h_group = v // 5
      when 10..21
        @w_group = (v - 10) % 6
        @h_group = 2 + (v - 10) // 6
      else # 22..31
        @w_group = (v - 22) % 5 + 1
        @h_group = 4 + (v - 22) // 5
      end

      @width = WIDTHS[@w_group]
      @height = HEIGHTS[@h_group]
    end
  end

  struct Version < AbstractQR::Version
    @value : VersionValue
    @symbol_size : SymbolDimension
    @mode_indicator_length : Int32

    def initialize(@value : VersionValue)
      @symbol_size = SymbolDimension.new(@value)
      @mode_indicator_length = 3
    end

    def self.new(str : String)
      self.new(VersionValue.parse(str))
    end

    def self.new(value : Int)
      self.new(VersionValue.new(value.to_u8))
    end

    def self.new(width : Int, height : Int)
      self.new("R#{height}x#{width}")
    end

    # Returns a tuple of vertical timing pattern line positions
    # except the ones on both edges.
    protected def v_timing_lines_pos
      case @symbol_size.w_group
      when 0
        Tuple.new
      when 1
        {21}
      when 2
        {19, 39}
      when 3
        {25, 51}
      when 4
        {23, 49, 73}
      when 5
        {27, 55, 81, 109}
      else
        raise "Invalid w_group"
      end
    end

    # Number of the modules that are available for writing the actual
    # data payload.
    protected def raw_data_mods_count
      v_timing_lines_count = v_timing_lines_pos.size

      # Also includes corner finder pattern
      timing_pattern_mod_h = @symbol_size.width * 2 - 13 - (6 * v_timing_lines_count)
      timing_pattern_mod_v = @symbol_size.height * 2 - 15 + (@symbol_size.height - 6) * v_timing_lines_count

      timing_pattern_mod = timing_pattern_mod_h + timing_pattern_mod_v
      timing_pattern_mod += @symbol_size.height > 9 ? 2 : 1 # adjust white corner finder module
      timing_pattern_mod -= 14 if @symbol_size.height < 8   # adjust height lower than finder + separator

      align_pattern_mod = 18 * v_timing_lines_count

      func_pattern_mod = 89 + align_pattern_mod + timing_pattern_mod
      fvi_mod = 36 # Format and version info modules

      @symbol_size.width * @symbol_size.height - func_pattern_mod - fvi_mod
    end

    # Maximum number of data codewords that can be contained in the rMQR Code
    # symbol of this version, including the number of error correction codewords.
    protected def raw_max_data_codewords
      raw_data_mods_count // 8
    end

    # Maximum number of data codewords that can be contained in the rMQR Code
    # symbol of this version. This does not include the number of error correction
    # codewords.
    def max_data_codewords(ecl : ECC::Level)
      ecc_codewords = EC_CODEWORDS_PER_BLOCK_RMQR[ecl.to_s][@value.value + 1] * EC_BLOCKS_RMQR[ecl.to_s][@value.value + 1]
      raise "Invalid EC level or version" if ecc_codewords < 0
      raw_max_data_codewords - ecc_codewords
    end

    # Maximum number of data bits that can be contained in the rMQR Code
    # symbol of this version. This does not include the number of error correction
    # codewords.
    def max_data_bits(ecl : ECC::Level)
      max_data_codewords(ecl) * 8
    end

    def <=>(other : Int)
      self.to_i <=> other
    end

    def to_i
      value.to_i
    end

    {% begin %}
      {% version_values = VersionValue.constants.map { |x| parse_type("VersionValue::#{x}") } %}

      ORDERED_BY_HEIGHT = StaticArray[{{ version_values.splat }}].sort do |a, b|
        a_size = SymbolDimension.new(a)
        b_size = SymbolDimension.new(b)

        cmp = a_size.height <=> b_size.height
        cmp = a_size.width <=> b_size.width if cmp == 0
        cmp
      end

      ORDERED_BY_WIDTH = StaticArray[{{ version_values.splat }}].sort do |a, b|
        a_size = SymbolDimension.new(a)
        b_size = SymbolDimension.new(b)

        cmp = a_size.width <=> b_size.width
        cmp = a_size.height <=> b_size.height if cmp == 0
        cmp
      end

      ORDERED_BY_AREA = StaticArray[{{ version_values.splat }}].sort do |a, b|
        a_size = SymbolDimension.new(a)
        b_size = SymbolDimension.new(b)

        a_size.width * a_size.height <=> b_size.width * b_size.height
      end

      ORDERED = {ORDERED_BY_AREA, ORDERED_BY_WIDTH, ORDERED_BY_HEIGHT}
    {% end %}
  end
end
