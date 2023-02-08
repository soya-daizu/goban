require "../abstract/version"

struct Goban::QR
  # Represents a version number of the QR Code symbol.
  # Possible versions range from 1 to 40, and the higher the number,
  # the large the size of the final QR Code symbol.
  struct Version < AbstractQR::Version
    MIN =  1_u8
    MAX = 40_u8

    @value : UInt8
    @symbol_size : Int32
    @mode_indicator_length : Int32

    def initialize(value)
      raise "Invalid version number" unless (MIN..MAX).includes?(value)
      @value = value.to_u8
      @symbol_size = 4 * @value + 17 # 21 + 4(v - 1)
      @mode_indicator_length = 4
    end

    # Returns a list of the alignment pattern positions for this version.
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

      timing_pattern_mod = (@symbol_size - 16) * 2
      overlaps = g * 10 # Overlaps of timing patterns and align patterns

      func_pattern_mod = 192 + timing_pattern_mod - overlaps
      if v > 1
        n = g + 1
        # 5^2(1 + ∑[k=1 .. n-1](2k + 3))
        align_pattern_mod = 25 * (n ** 2 + 2 * n - 2)

        func_pattern_mod += align_pattern_mod
      end
      fvi_mod = v < 7 ? 31 : 67 # Format and version info modules

      symbol_size ** 2 - func_pattern_mod - fvi_mod
    end

    # Maximum number of data codewords that can be contained in the QR Code
    # symbol of this version, including the number of error correction codewords.
    protected def raw_max_data_codewords
      raw_data_mods_count // 8
    end

    # Maximum number of data codewords that can be contained in the QR Code
    # symbol of this version. This does not include the number of error correction
    # codewords.
    def max_data_codewords(ecl : ECC::Level)
      ecc_codewords = EC_CODEWORDS_PER_BLOCK_QR[ecl.value][@value] * EC_BLOCKS_QR[ecl.value][@value]
      raise "Invalid EC level or version" if ecc_codewords < 0
      raw_max_data_codewords - ecc_codewords
    end

    # Maximum number of data bits that can be contained in the QR Code
    # symbol of this version. This does not include the number of error correction
    # codewords.
    def max_data_bits(ecl : ECC::Level)
      max_data_codewords(ecl) * 8
    end
  end
end
