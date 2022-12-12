struct Goban::QR
  # Represents a version number of the QR Code symbol.
  # Possible versions range from 1 to 40, and the higher the number,
  # the large the size of the final QR Code symbol.
  struct Version
    include Comparable(Int)

    MIN =  1_u8
    MAX = 40_u8

    getter value : UInt8

    def initialize(value : Int)
      raise "Invalid version number" unless (MIN..MAX).includes?(value)
      @value = value.to_u8
    end

    def <=>(other : Int)
      @value <=> other
    end

    def to_i
      value
    end

    # Size of the QR Code symbol for this version.
    def symbol_size
      4 * @value + 17 # 21 + 4(v - 1)
    end

    # Number of the timing pattern modules for this version.
    protected def timing_pattern_mods_count
      4 * @value + 1 # 5 + 4(v - 1)
    end

    # Returns a list of the alignment pattern positions for thie version.
    # The list may include positions in which drawing is not allowed due
    # to overlap with the finder pattern, etc.
    protected def alignment_pattern_positions
      v = @value
      return [] of Int32 if v == 1

      g = v // 7 + 2
      step = v == 32 ? 26 : (v * 4 + g * 2 + 1) // (g * 2 - 2) * 2
      result = (0...g - 1).map do |i|
        symbol_size - 7 - i * step
      end
      result.push(6)
      result.reverse!

      result
    end

    # Number of the modules that are available for writing the actual
    # data payload.
    protected def raw_data_mods_count
      v = @value
      g = v // 7

      timing_pattern_mod = timing_pattern_mods_count * 2
      if v == 1
        align_pattern_mod = 0
      else
        n = g + 1
        # 25(1 + ∑[k=1..n-1](2k+3))
        align_pattern_mod = 25 * (n ** 2 + 2 * n - 2)
      end
      overlaps = g * 10 # Overlaps of timing patterns and align patterns

      func_pattern_mod = 192 + timing_pattern_mod + align_pattern_mod - overlaps
      fvi_mod = v < 7 ? 31 : 67 # Format and version info modules

      symbol_size ** 2 - func_pattern_mod - fvi_mod
    end

    # Maximum number of codewords that can be contained in the QR Code
    # symbol of this version.
    def max_data_codewords(ecl : ECLevel)
      raw_max_data_codewords = raw_data_mods_count // 8
      ecc_codewords = ECC_CODEWORDS_PER_BLOCK[ecl.value][@value] * ERROR_CORRECTION_BLOCKS[ecl.value][@value]
      raw_max_data_codewords - ecc_codewords
    end
  end
end
