require "../abstract/version"

struct Goban::MQR
  # Represents a version number of the Micro QR Code symbol.
  # Possible versions range from 1 to 4, and the higher the number,
  # the large the size of the final Micro QR Code symbol.
  struct Version < AbstractQR::Version
    MIN = 1_u8
    MAX = 4_u8

    @value : UInt8
    @symbol_size : Int32

    def initialize(value)
      raise "Invalid version number" unless (MIN..MAX).includes?(value)
      @value = value.to_u8
      @symbol_size = 2 * @value + 9 # 11 + 2(v - 1)
    end

    # Number of the modules that are available for writing the actual
    # data payload.
    protected def raw_data_mods_count
      timing_pattern_mod = (@symbol_size - 8) * 2

      func_pattern_mod = 64 + timing_pattern_mod
      fvi_mod = 15 # Format and version info modules

      symbol_size ** 2 - func_pattern_mod - fvi_mod
    end

    # Maximum number of data codewords that can be contained in the Micro QR Code
    # symbol of this version, including the number of error correction codewords.
    protected def raw_max_data_codewords
      # Version M1 and M3 have one codeword with the length of 4 bits
      # so we're doing ceiling division here to simulate proper behavior
      (raw_data_mods_count / 8).ceil.to_i
    end

    # Maximum number of data codewords that can be contained in the Micro QR Code
    # symbol of this version. This does not include the number of error correction
    # codewords.
    def max_data_codewords(ecl : ECC::Level)
      ecc_codewords = EC_CODEWORDS_MQR[ecl.value][@value]
      raise "Invalid EC level or version" if ecc_codewords < 0
      raw_max_data_codewords - ecc_codewords
    end

    # Maximum number of data bits that can be contained in the Micro QR Code
    # symbol of this version. This does not include the number of error correction
    # codewords.
    def max_data_bits(ecl : ECC::Level)
      ecc_codewords = EC_CODEWORDS_MQR[ecl.value][@value]
      raise "Invalid EC level or version" if ecc_codewords < 0
      raw_data_mods_count - ecc_codewords * 8
    end
  end
end
