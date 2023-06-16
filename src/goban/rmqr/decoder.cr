struct Goban::RMQR < Goban::AbstractQR
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
      raise InputError.new("Canvas dimention not correct") unless canvas.size_x > canvas.size_y

      version = Version.new(canvas.size_x, canvas.size_y) rescue nil
      raise InputError.new("Invalid version") unless version
      actual_version, ecl = self.read_format(canvas)
      raise VersionMismatchError.new(actual_version.to_i) unless actual_version == version
      p! version, ecl

      # For reserving function patterns
      Template.draw_function_patterns(canvas, version, ecl)
      Mask.new.apply_to(canvas)

      raw_data_codewords = self.read_data_codewords(canvas, version)
      p! raw_data_codewords
      data_codewords = ECC::RSDeflator.deflate_codewords(raw_data_codewords, version, ecl)
      p! data_codewords

      bit_stream = BitStream.new(data_codewords)
      segments = Array(Segment).new
      while bit_stream.read_pos < bit_stream.size
        header_bits = bit_stream.read_bits(3)
        break if header_bits == 0b000

        mode = Segment::Mode.from_bits(header_bits, version)

        cci_bits_count = mode.cci_bits_count(version)
        char_count = bit_stream.read_bits(cci_bits_count).to_i

        segment = Segment.new(mode, char_count, bit_stream)
        segments.push(segment)
        bit_stream.read_pos += segment.bit_size
      end

      RMQR.new(version, ecl, segments, canvas)
    end

    private def read_format(canvas : Canvas(UInt8))
      width, height = canvas.size_x, canvas.size_y

      left_f_bits, right_f_bits = 0, 0
      (0...18).reverse_each do |i|
        x = 8 + i // 5
        y = 1 + i % 5
        left_f_bits = (left_f_bits << 1) | canvas[x, y]

        if i < 15
          x = width - 8 + i // 5
          y = height - 6 + i % 5
        else
          x = width + i - 20
          y = height - 6
        end
        right_f_bits = (right_f_bits << 1) | canvas[x, y]
      end

      left_f_best, left_f_best_diff = nil, 18
      right_f_best, right_f_best_diff = nil, 18
      Version::VERSION_BITS.each_with_index do |bits_group, ver|
        ver = Version.new(ver)

        bits_group.each do |key, bits_pair|
          ecl = ECC::Level.parse(key.to_s)

          left_bits, right_bits = bits_pair
          left_f_diff = count_diff(left_bits, left_f_bits)
          right_f_diff = count_diff(right_bits, right_f_bits)

          if left_f_diff < left_f_best_diff
            left_f_best = {ver, ecl}
            left_f_best_diff = left_f_diff
          end
          if right_f_diff < right_f_best_diff
            right_f_best = {ver, ecl}
            right_f_best_diff = right_f_diff
          end
        end
      end

      raise InputError.new("Unable to read format information") if left_f_best_diff > 3 && right_f_best_diff > 3
      raise InputError.new("Unable to read format information") if !left_f_best || !right_f_best

      left_f_best_diff <= right_f_best_diff ? left_f_best : right_f_best
    end

    private def read_data_codewords(canvas : Canvas(UInt8), version : Version)
      width, height = canvas.size_x, canvas.size_y
      data_codewords = Slice(UInt8).new(version.raw_max_data_codewords, 0)
      data_length = data_codewords.size * 8

      i = 0
      upward = true      # Current filling direction
      base_x = width - 2 # Zig zag filling starts from bottom right
      while base_x > 1
        (0...height).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : height - 1 - base_y
            bit = canvas[x, y]
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
