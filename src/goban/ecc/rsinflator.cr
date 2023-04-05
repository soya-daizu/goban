module Goban::ECC
  # Module for generating redundant Reed-Solomon error correction bits.
  module RSInflator
    extend self

    def inflate_codewords(codewords : Slice(UInt8), version : QR::Version | RMQR::Version, ecl : Level)
      raise "Codewords size mismatch" if codewords.size != version.max_data_codewords(ecl)

      case version
      when QR::Version
        ec_blocks_count = EC_BLOCKS_QR[ecl.to_s][version.to_i]
        ec_block_size = EC_CODEWORDS_PER_BLOCK_QR[ecl.to_s][version.to_i]
      when RMQR::Version
        ec_blocks_count = EC_BLOCKS_RMQR[ecl.to_s][version.to_i + 1]
        ec_block_size = EC_CODEWORDS_PER_BLOCK_RMQR[ecl.to_s][version.to_i + 1]
      else
        raise "Unknown QR Type"
      end

      raw_codewords_count = version.raw_data_mods_count // 8
      short_blocks_count = ec_blocks_count - raw_codewords_count % ec_blocks_count
      short_block_size = raw_codewords_count // ec_blocks_count - ec_block_size

      result = Slice(UInt8).new(raw_codewords_count)
      gen_poly = self.get_generator_polynomial(ec_block_size)
      k = 0
      ec_blocks_count.times do |i|
        data_size = short_block_size + (i >= short_blocks_count ? 1 : 0)
        data = codewords[k, data_size]
        k += data_size

        data_size.times do |j|
          result[i + ec_blocks_count*j] = data[j]
        end

        ecc = self.poly_div(data, gen_poly)
        ec_block_size.times do |j|
          result[i + codewords.size + ec_blocks_count*j] = ecc[j]
        end
      end

      result
    end

    def inflate_codewords(codewords : Slice(UInt8), version : MQR::Version, ecl : Level)
      raise "Codewords size mismatch" if codewords.size != version.max_data_codewords(ecl)

      ec_block_size = EC_CODEWORDS_MQR[ecl.to_s][version.to_i]
      raw_codewords_count = version.raw_max_data_codewords

      result = Slice(UInt8).new(raw_codewords_count)

      data = codewords
      # Version M1 and M3 have a shorter last codeword of 4 bits,
      # so we are shifting it by four here
      data[data.size - 1] >>= 4 if version == 1 || version == 3
      data.copy_to(result)

      gen_poly = self.get_generator_polynomial(ec_block_size)
      ecc = self.poly_div(data, gen_poly)
      ec_block_size.times do |j|
        result[data.size + j] = ecc[j]
      end

      result
    end

    private def get_generator_polynomial(for degree : Int)
      result = Array(UInt8).new(degree - 1, 0)
      result.push(1)

      root = 1
      degree.times do |i|
        degree.times do |j|
          result[j] = gf_mul(result[j], root)
          result[j] ^= result[j + 1] if j + 1 < result.size
        end

        root = GF256_MAP[i + 1]
      end

      result
    end

    private def poly_div(data : Slice(UInt8), generator : Array(UInt8))
      result = Array(UInt8).new(generator.size, 0)
      data.each do |b|
        factor = b ^ result.shift
        result.push(0)
        result.size.times do |i|
          y = generator[i]
          result[i] ^= gf_mul(y, factor)
        end
      end

      result
    end

    private def gf_mul(x : Int, y : Int)
      return 0_u8 if x == 0 || y == 0
      GF256_MAP[(GF256_INVMAP[x].to_i + GF256_INVMAP[y]) % 255]
    end

    # Tables of galois field values

    GF256_MAP = begin
      a = uninitialized UInt8[256]
      a[0] = 1

      (1...255).each do |i|
        v = a[i - 1].to_i * 2
        a[i] = (v >= 256 ? (v ^ 0x11d) : v).to_u8
      end

      a
    end

    GF256_INVMAP = begin
      a = uninitialized UInt8[256]

      (0...255).each do |i|
        a[GF256_MAP[i]] = i.to_u8
      end

      a
    end
  end
end
