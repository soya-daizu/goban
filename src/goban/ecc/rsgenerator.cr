module Goban::ECC
  # Module for generating redundant Reed-Solomon error correction bits.
  module RSGenerator
    extend self

    def add_ec_codewords(codewords : Slice(UInt8), version : QR::Version, ecl : Level)
      raise "Codewords size mismatch" if codewords.size != version.max_data_codewords(ecl)

      ec_blocks_count = ERROR_CORRECTION_BLOCKS[ecl.value][version.value]
      block_ecc_size = ECC_CODEWORDS_PER_BLOCK[ecl.value][version.value]
      raw_codewords = version.raw_data_mods_count // 8
      short_blocks_count = ec_blocks_count - raw_codewords % ec_blocks_count
      short_block_size = raw_codewords // ec_blocks_count

      blocks = Array(Array(UInt8)).new(ec_blocks_count)
      gen_poly = self.get_generator_polynomial(block_ecc_size)
      k = 0
      ec_blocks_count.times do |i|
        data_size = short_block_size - block_ecc_size + (i >= short_blocks_count ? 1 : 0)
        data = codewords[k, data_size].to_a
        k += data_size

        ec_codewords = self.poly_modulo(data, gen_poly)
        # Add a filler codeword if it's a short block
        data.push(0) if i < short_blocks_count
        data.concat(ec_codewords)
        blocks.push(data)
      end

      result = Array(UInt8).new(raw_codewords)
      (short_block_size + 1).times do |i|
        blocks.each_with_index do |block, j|
          # Add to the result unless it's a filler codeword or
          # if there is no short block involved in the given
          # version and ec level
          if i != short_block_size - block_ecc_size || j >= short_blocks_count
            result.push(block[i])
          end
        end
      end

      result
    end

    private def get_generator_polynomial(for degree : Int)
      result = Array(UInt8).new(degree - 1, 0)
      result.push(1)

      root = 1
      degree.times do |i|
        degree.times do |j|
          temp = result[j]
          result[j] = gf_mul(result[j], root)
          result[j] ^= result[j + 1] if j + 1 < result.size
        end

        root = GF256_MAP[i + 1]
      end

      result
    end

    private def poly_modulo(data : Array(UInt8), generator : Array(UInt8))
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
  end
end
