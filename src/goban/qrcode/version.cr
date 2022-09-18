struct Goban::QRCode
  struct Version
    include Comparable(Int)

    MIN =  1_u8
    MAX = 40_u8

    getter value : UInt8

    def initialize(@value)
      raise "Invalid version number" unless (MIN..MAX).includes?(@value)
    end

    def <=>(other : Int)
      @value <=> other
    end

    def symbol_size
      4 * @value + 17 # 21 + 4(v - 1)
    end

    def timing_pattern_mods_count
      4 * @value + 1 # 5 + 4(v - 1)
    end

    def raw_data_mods
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

    def max_data_codewords(ecl : ECLevel)
      raw_max_data_codewords = raw_data_mods // 8
      ecc_codewords = ECC_CODEWORDS_PER_BLOCK[ecl.value][@value] * ERROR_CORRECTION_BLOCKS[ecl.value][@value]
      raw_max_data_codewords - ecc_codewords
    end
  end
end
