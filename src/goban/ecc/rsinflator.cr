module Goban::ECC
  # Module for generating redundant Reed-Solomon error correction bits.
  module RSInflator
    extend self

    GEN_POLYS = begin
      a = uninitialized GFPoly[31]

      a[0] = GFPoly.new(Slice[1_u8])
      (1_u8..30_u8).each do |d|
        last_gen = a[d - 1]
        a[d] = last_gen.mul(Slice[1_u8, GF.exp(d - 1)])
      end

      a
    end

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

      raw_codewords_count = version.raw_max_data_codewords
      short_blocks_count = ec_blocks_count - raw_codewords_count % ec_blocks_count
      short_block_size = raw_codewords_count // ec_blocks_count - ec_block_size

      result = Slice(UInt8).new(raw_codewords_count)
      gen_poly = GEN_POLYS[ec_block_size]
      k = 0
      ec_blocks_count.times do |i|
        is_short_block = i < short_blocks_count
        data_size = short_block_size + (is_short_block ? 0 : 1)
        data = codewords[k, data_size]
        k += data_size

        short_block_size.times do |j|
          result[i + ec_blocks_count*j] = data[j]
        end
        if !is_short_block
          j = data_size - 1
          result[i + ec_blocks_count*j - short_blocks_count] = data[j]
        end

        data_poly = GFPoly.new(data, truncate: false)
        _, ecc = data_poly.div(gen_poly)
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
      data.copy_to(result)

      data_poly = GFPoly.new(data)
      gen_poly = GEN_POLYS[ec_block_size]
      _, ecc = data_poly.div(gen_poly)
      ecc.data.copy_to(result[data.size, ecc.data.size])

      result
    end
  end
end
