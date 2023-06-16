struct Goban::MQR < Goban::AbstractQR
  module Decoder
    extend self

    class VersionMismatchError < Exception
      getter actual_version : Int32

      def initialize(@actual_version)
        @message = "Symbol size does not match the detected version"
      end
    end

    def decode_to_string(canvas : Canvas(UInt8))
      segments = self.decode(canvas).segments
      segments.join { |seg| seg.text }
    end

    def decode(canvas : Canvas(UInt8))
      raise InputError.new("Canvas not square") unless canvas.size_x == canvas.size_y

      version = (canvas.size_x - 9) // 2
      raise InputError.new("Invalid version") unless (Version::MIN..Version::MAX).includes?(version)
      mask, symbol_num = self.read_format(canvas)
      ecl = nil
      Version::SYMBOL_NUMS.each_with_index do |group, ver|
        group.each do |key, bits|
          next unless bits == symbol_num
          raise VersionMismatchError.new(ver) unless ver == version
          ecl = ECC::Level.parse(key.to_s)
          break
        end
        break if ecl
      end
      raise InputError.new("Unalbe to read format information") unless ecl
      version = Version.new(version)
      # p! version, mask, ecl

      # For reserving function patterns
      Template.draw_function_patterns(canvas)
      mask.apply_to(canvas)

      raw_data_codewords = self.read_data_codewords(canvas, version, ecl)
      data_codewords = ECC::RSDeflator.deflate_codewords(raw_data_codewords, version, ecl)

      bit_stream = BitStream.new(data_codewords)
      segments = Array(Segment).new
      while bit_stream.read_pos < bit_stream.size
        header_bits_size = version.to_i - 1
        header_bits = bit_stream.read_bits(header_bits_size)
        mode = Segment::Mode.from_bits(header_bits, version)

        cci_bits_count = mode.cci_bits_count(version)
        raise InternalError.new("Invalid segment") if !cci_bits_count
        char_count = bit_stream.read_bits(cci_bits_count).to_i

        segment = Segment.new(mode, char_count, bit_stream)
        segments.push(segment)
        bit_stream.read_pos += segment.bit_size

        terminator_bits_size = 3 + 2 * header_bits_size
        lookahead = bit_stream.read_bits(terminator_bits_size)
        break if lookahead == 0b000000000
        bit_stream.read_pos -= terminator_bits_size
      end

      MQR.new(version, ecl, segments, canvas, mask)
    end

    private def read_format(canvas : Canvas(UInt8))
      size = canvas.size_x

      f_bits = 0
      (8..14).reverse_each do |i|
        pos = 15 - i
        f_bits = (f_bits << 1) | canvas[pos, 8]
      end
      (0..7).reverse_each do |i|
        pos = i + 1
        f_bits = (f_bits << 1) | canvas[8, pos]
      end

      f_best, f_best_diff = nil, 15
      Mask::FORMAT_BITS.each_with_index do |bits_group, mask|
        mask = Mask.new(mask)

        bits_group.each_with_index do |bits, symbol_num|
          f_diff = count_diff(bits, f_bits)
          if f_diff < f_best_diff
            f_best = {mask, symbol_num}
            f_best_diff = f_diff
          end
        end
      end

      raise InputError.new("Unable to read format information") if f_best_diff > 3 || !f_best

      f_best
    end

    private def read_data_codewords(canvas : Canvas(UInt8), version : Version, ecl : ECC::Level)
      size = canvas.size
      data_codewords = Slice(UInt8).new(version.raw_max_data_codewords, 0)
      data_length = data_codewords.size * 8

      i = 0
      upward = true     # Current reading direction
      base_x = size - 1 # Zig zag reading starts from bottom right
      while base_x > 0
        (0...size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : size - 1 - base_y
            bit = canvas[x, y]
            next if bit & 0x80 > 0
            return data_codewords if i >= data_length

            data_i = i >> 3
            data_codewords[data_i] = (data_codewords[data_i] << 1) | bit
            if version == 1 && data_i == 2 ||
               version == 3 && ecl.low? && data_i == 10 ||
               version == 3 && ecl.medium? && data_i == 8
              i += 1
              i += 4 if i % 4 == 0
            else
              i += 1
            end
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
