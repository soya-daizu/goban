module Goban::ECC
  module RSDeflator
    extend self

    def deflate_codewords(codewords : Slice(UInt8), version : QR::Version | RMQR::Version, ecl : Level)
      data_codewords_count = version.max_data_codewords(ecl)

      case version
      when QR::Version
        ec_blocks_count = EC_BLOCKS_QR[ecl.to_s][version.to_i]
        ec_block_size = EC_CODEWORDS_PER_BLOCK_QR[ecl.to_s][version.to_i]
      when RMQR::Version
        ec_blocks_count = EC_BLOCKS_RMQR[ecl.to_s][version.to_i + 1]
        ec_block_size = EC_CODEWORDS_PER_BLOCK_RMQR[ecl.to_s][version.to_i + 1]
      else
        raise InternalError.new("Unknown QR Type")
      end

      raw_codewords_count = version.raw_max_data_codewords
      short_blocks_count = ec_blocks_count - raw_codewords_count % ec_blocks_count
      short_block_size = raw_codewords_count // ec_blocks_count

      result = Slice(UInt8).new(raw_codewords_count)
      k = 0
      ec_blocks_count.times do |i|
        is_short_block = i < short_blocks_count
        block_size = short_block_size + (is_short_block ? 0 : 1)
        data_size = block_size - ec_block_size
        unweaved = Slice(UInt8).new(block_size)

        short_data_size = short_block_size - ec_block_size
        short_data_size.times do |j|
          unweaved[j] = codewords[i + ec_blocks_count*j]
        end
        if !is_short_block
          j = data_size - 1
          unweaved[j] = codewords[i + ec_blocks_count*j - short_blocks_count]
        end

        ec_block_size.times do |j|
          unweaved[data_size + j] = codewords[i + data_codewords_count + ec_blocks_count*j]
        end

        corrected = self.decode_block(unweaved, ec_block_size)[0, data_size]
        result[k, data_size].copy_from(corrected)
        k += data_size
      end

      result
    end

    def deflate_codewords(codewords : Slice(UInt8), version : MQR::Version, ecl : Level)
      data_codewords_count = version.max_data_codewords(ecl)

      ec_block_size = EC_CODEWORDS_MQR[ecl.to_s][version.to_i]
      raw_codewords_count = version.raw_max_data_codewords
      block_size = raw_codewords_count
      data_size = block_size - ec_block_size

      self.decode_block(codewords, ec_block_size)[0, data_size]
    end

    private def decode_block(block : Slice(UInt8), ec_block_size : Int)
      has_no_err = true
      block_poly = GFPoly.new(block)
      syndromes = Slice(UInt8).new(ec_block_size)
      syndromes.size.times do |i|
        eval = block_poly.eval(GF.exp(i.to_u8))
        syndromes[syndromes.size - 1 - i] = eval
        has_no_err = false unless eval == 0
      end
      return block if has_no_err

      syndromes = GFPoly.new(syndromes)
      err_locator, err_evaluator = euclidean(syndromes, ec_block_size)
      err_loc = find_err_loc(err_locator)

      correct_err(block, err_evaluator, err_loc)
    end

    private def euclidean(syndromes : GFPoly, ec_block_size : Int)
      a = GFPoly.build_mono(ec_block_size, 1)
      b = syndromes

      r_last, r = a, b
      t_last, t = GFPoly.zero, GFPoly.one

      while r.degree >= ec_block_size // 2
        r_last_last, t_last_last = r_last, t_last
        r_last, t_last = r, t

        q, r = r_last_last.div2(r_last)
        t = q.mul(t_last).add_or_sub(t_last_last)

        raise InputError.new("Unable to correct error") if r.degree >= r_last.degree
      end

      raise InputError.new("Unable to correct error") if t.get_coeff(0) == 0

      inv = GF.inv(t.get_coeff(0))
      {t.scale(inv), r.scale(inv)}
    end

    private def find_err_loc(locator : GFPoly)
      err_cap = locator.degree
      return Slice[locator.get_coeff(1)] if err_cap == 1

      result = Slice(UInt8).new(err_cap)
      i, err_count = 1, 0
      while i < 256 && err_count < err_cap
        if locator.eval(i) == 0
          result[err_count] = GF.inv(i.to_u8)
          err_count += 1
        end
        i += 1
      end
      raise InputError.new("Unable to correct error") unless err_count == err_cap

      result
    end

    private def correct_err(block : Slice(UInt8), evaluator : GFPoly, loc : Slice(UInt8))
      loc.each_with_index do |l, i|
        pos = block.size - 1 - GF.log(l)
        raise InternalError.new("Unable to correct error") if pos < 0
        l_inv = GF.inv(l)

        denominator = 1_u8
        loc.each_with_index do |ll, j|
          next if i == j
          denominator = GF.mul(denominator, GF.add_or_sub(1, GF.mul(ll, l_inv)))
        end
        magnitude = GF.mul(evaluator.eval(l_inv), GF.inv(denominator))
        block[pos] = GF.add_or_sub(block[pos], magnitude)
      end

      block
    end
  end
end
