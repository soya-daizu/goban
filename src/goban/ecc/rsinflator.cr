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

    # Logarithms of the coefficients of each generator polynomial except the
    # leading one, which is always 1. The coefficients are all nonzero.
    GEN_POLY_LOGS = begin
      GEN_POLYS.map do |poly|
        Slice(UInt8).new(poly.size - 1) do |i|
          coeff = poly[i + 1]
          raise InternalError.new("Zero coefficient in generator polynomial") if coeff == 0
          GF.log(coeff)
        end
      end
    end

    # `GF::EXP_TABLE` repeated twice, so that the sum of two logarithms can
    # be looked up without taking the modulo.
    EXP_TABLE_2X = begin
      a = uninitialized UInt8[510]
      510.times { |i| a[i] = GF::EXP_TABLE[i % 255] }
      a
    end

    def inflate_codewords(codewords : Slice(UInt8), version : QR::Version | RMQR::Version, ecl : Level)
      raise InputError.new("Codewords size mismatch") if codewords.size != version.max_data_codewords(ecl)

      case version
      when QR::Version
        ec_blocks_count = ECC.lookup(ECC::EC_BLOCKS_QR, ecl)[version.to_i]
        ec_block_size = ECC.lookup(ECC::EC_CODEWORDS_PER_BLOCK_QR, ecl)[version.to_i]
      when RMQR::Version
        ec_blocks_count = ECC.lookup(ECC::EC_BLOCKS_RMQR, ecl)[version.to_i + 1]
        ec_block_size = ECC.lookup(ECC::EC_CODEWORDS_PER_BLOCK_RMQR, ecl)[version.to_i + 1]
      else
        raise InternalError.new("Unknown QR Type")
      end

      raw_codewords_count = version.raw_max_data_codewords
      short_blocks_count = ec_blocks_count - raw_codewords_count % ec_blocks_count
      short_block_size = raw_codewords_count // ec_blocks_count - ec_block_size

      result = Slice(UInt8).new(raw_codewords_count)
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

        ecc = compute_ecc(data, ec_block_size)
        ec_block_size.times do |j|
          result[i + codewords.size + ec_blocks_count*j] = ecc[j]
        end
      end

      result
    end

    def inflate_codewords(codewords : Slice(UInt8), version : MQR::Version, ecl : Level)
      raise InputError.new("Codewords size mismatch") if codewords.size != version.max_data_codewords(ecl)

      ec_block_size = ECC.lookup(ECC::EC_CODEWORDS_MQR, ecl)[version.to_i]
      raw_codewords_count = version.raw_max_data_codewords

      result = Slice(UInt8).new(raw_codewords_count)

      data = codewords
      data.copy_to(result)

      ecc = compute_ecc(data, ec_block_size)
      ecc.copy_to(result[data.size, ec_block_size])

      result
    end

    # Computes the error correction codewords, which are the remainder of
    # `data(x) * x^ec_block_size` divided by the generator polynomial.
    # The division is done in place on the remainder register, one data
    # codeword at a time.
    private def compute_ecc(data : Slice(UInt8), ec_block_size : Int)
      gen_logs = GEN_POLY_LOGS[ec_block_size]
      ecc = Slice(UInt8).new(ec_block_size)
      last = ec_block_size - 1

      data.each do |byte|
        factor = byte ^ ecc.unsafe_fetch(0)
        # Shift the register by one codeword (the ranges overlap)
        (ecc.to_unsafe + 1).move_to(ecc.to_unsafe, last)
        ecc.unsafe_put(last, 0_u8)
        next if factor == 0

        factor_log = GF::LOG_TABLE[factor].to_i32
        ec_block_size.times do |j|
          ecc.unsafe_put(j, ecc.unsafe_fetch(j) ^ EXP_TABLE_2X.unsafe_fetch(gen_logs.unsafe_fetch(j).to_i32 + factor_log))
        end
      end

      ecc
    end
  end
end
