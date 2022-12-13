struct Goban::MQR
  # Represents a version number of the Micro QR Code symbol.
  # Possible versions range from 1 to 4, and the higher the number,
  # the large the size of the final Micro QR Code symbol.
  struct Version
    include Comparable(Int)

    MIN = 1_u8
    MAX = 4_u8

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

    # Size of the Micro QR Code symbol for this version.
    def symbol_size
      2 * @value + 9 # 11 + 2(v - 1)
    end

    # Number of the timing pattern modules in one direction for this version.
    protected def timing_pattern_mods_count
      2 * @value + 1 # 3 + 2(v - 1)
    end

    # Number of the modules that are available for writing the actual
    # data payload.
    protected def raw_data_mods_count
      timing_pattern_mod = timing_pattern_mods_count * 2

      func_pattern_mod = 64 + timing_pattern_mod
      fvi_mod = 15 # Format and version info modules

      symbol_size ** 2 - func_pattern_mod - fvi_mod
    end

    # Maximum number of codewords that can be contained in the Micro QR Code
    # symbol of this version.
    def max_data_codewords(ecl : ECC::Level)
      raw_max_data_codewords = raw_data_mods_count // 8
      ecc_codewords = ECC_CODEWORDS_MQR[ecl.value][@value]
      raw_max_data_codewords - ecc_codewords
    end
  end
end

