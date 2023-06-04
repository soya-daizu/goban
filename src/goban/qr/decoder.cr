struct Goban::QR < Goban::AbstractQR
  module Decoder
    extend self

    class VersionMismatchError < Exception
      getter actual_version : Int32

      def initialize(@actual_version)
      end
    end

    def decode_to_string(matrix : Matrix(UInt8))
      segments = self.decode(matrix).segments
      segments.join { |seg| seg.text }
    end

    def decode(matrix : Matrix(UInt8))
      raise InputError.new("Matrix not square") unless matrix.size_x == matrix.size_y

      version = self.read_version(matrix)
      mask, ecl = self.read_format(matrix)

      # For reserving function patterns
      Template.draw_function_patterns(matrix, version)
      mask.apply_to(matrix)

      raw_data_codewords = self.read_data_codewords(matrix, version)
      data_codewords = ECC::RSDeflator.deflate_codewords(raw_data_codewords, version, ecl)

      bit_stream = BitStream.new(data_codewords)
      segments = Array(Segment).new
      while bit_stream.read_pos < bit_stream.size
        header_bits = bit_stream.read_bits(4)
        break if header_bits == 0b0000

        mode = Segment::Mode.from_bits(header_bits, version)

        cci_bits_count = mode.cci_bits_count(version)
        char_count = bit_stream.read_bits(cci_bits_count).to_i

        segment = Segment.new(mode, char_count, bit_stream)
        segments.push(segment)
        bit_stream.read_pos += segment.bit_size
      end

      QR.new(version, ecl, segments, matrix, mask)
    end

    private def read_version(matrix : Matrix(UInt8))
      size = matrix.size_x
      v = (size - 17) // 4 # Version estimated from the matrix size
      raise InputError.new("Invalid version") unless (Version::MIN..Version::MAX).includes?(v)
      return Version.new(v) if v < 7

      v1_bits, v2_bits = 0, 0
      (0...18).reverse_each do |i|
        x = size - 11 + i % 3
        y = i // 3

        v1_bits = (v1_bits << 1) | matrix[x, y]
        v2_bits = (v2_bits << 1) | matrix[y, x]
      end

      v1_best, v1_best_diff = 0, 18
      v2_best, v2_best_diff = 0, 18
      Version::VERSION_BITS.skip(7).each_with_index do |bits, ver|
        ver = ver + 7

        v1_diff = count_diff(bits, v1_bits)
        if v1_diff < v1_best_diff
          v1_best = ver
          v1_best_diff = v1_diff
        end

        v2_diff = count_diff(bits, v2_bits)
        if v2_diff < v2_best_diff
          v2_best = ver
          v2_best_diff = v2_diff
        end
      end

      raise InputError.new("Unable to read version") if v1_best_diff > 3 && v2_best_diff > 3

      actual_version = v1_best_diff <= v2_best_diff ? v1_best : v2_best
      raise VersionMismatchError.new(actual_version) unless v == actual_version

      Version.new(actual_version)
    end

    private def read_format(matrix : Matrix(UInt8))
      size = matrix.size_x

      f1_bits, f2_bits = 0, 0
      (8..14).reverse_each do |i|
        pos = i == 8 ? 7 : (14 - i)
        f1_bits = (f1_bits << 1) | matrix[pos, 8]
        pos = size - 1 - (14 - i)
        f2_bits = (f2_bits << 1) | matrix[8, pos]
      end
      (0..7).reverse_each do |i|
        pos = i >= 6 ? i + 1 : i
        f1_bits = (f1_bits << 1) | matrix[8, pos]
        pos = size - 1 - i
        f2_bits = (f2_bits << 1) | matrix[pos, 8]
      end

      f1_best, f1_best_diff = nil, 15
      f2_best, f2_best_diff = nil, 15
      Mask::FORMAT_BITS.each_with_index do |bits_group, mask|
        mask = Mask.new(mask)

        bits_group.each do |ecl, bits|
          ecl = ECC::Level.parse(ecl.to_s)

          f1_diff = count_diff(bits, f1_bits)
          if f1_diff < f1_best_diff
            f1_best = {mask, ecl}
            f1_best_diff = f1_diff
          end

          f2_diff = count_diff(bits, f2_bits)
          if f2_diff < f2_best_diff
            f2_best = {mask, ecl}
            f2_best_diff = f2_diff
          end
        end
      end

      raise InputError.new("Unable to read format information") if (f1_best_diff > 3 && f2_best_diff > 3) ||
                                                                    !f1_best || !f2_best

      f1_best_diff <= f2_best_diff ? f1_best : f2_best
    end

    private def read_data_codewords(matrix : Matrix(UInt8), version : Version)
      size = matrix.size
      data_codewords = Slice(UInt8).new(version.raw_max_data_codewords, 0)
      data_length = data_codewords.size * 8

      i = 0
      upward = true     # Current reading direction
      base_x = size - 1 # Zig zag reading starts from bottom right
      while base_x > 0
        base_x = 5 if base_x == 6 # Skip vertical timing pattern

        (0...size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : size - 1 - base_y
            bit = matrix[x, y]
            next if bit & 0x80 > 0
            return data_codewords if i >= data_length

            data_codewords[i >> 3] = (data_codewords[i >> 3] << 1) | bit
            i += 1
          end
        end

        upward = !upward
        base_x -= 2
      end

      data_codewords
    end

    private def count_diff(x : Int, y : Int)
      z, count = (x ^ y), 0
      while z > 0
        z &= z - 1
        count += 1
      end

      count
    end
  end
end
