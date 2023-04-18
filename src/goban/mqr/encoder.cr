struct Goban::MQR < Goban::AbstractQR
  module Encoder
    extend self

    # Creates a new Micro QR Code object for the given string and error correction level.
    #
    # Note that Micro QR Codes have limited EC levels you can select depending on the length
    # of the text. In version M1, the EC level passed will just be ignored.
    #
    # See `QR::Encoder.encode_string` for more information.
    def encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium)
      segments, version = determine_version_and_segments(text, ecl)
      self.encode_segments(segments, ecl, version)
    end

    # Creates a new Micro QR Code object for the given data segments, error correction level, and
    # Micro QR Code version that is large enough to contain all the data in the segments.
    #
    # See `QR::Encoder.encode_segments` for more information.
    def encode_segments(segments : Array(Segment), ecl : ECC::Level, version : Version | Int)
      version = Version.new(version.to_i)
      bit_stream = BitStream.new(version.max_data_bits(ecl))
      segments.each do |segment|
        bit_stream.append_segment_bits(segment, version)
      end
      bit_stream.append_terminator_bits(version, ecl)
      bit_stream.append_padding_bits(version)

      codewords = ECC::RSInflator.inflate_codewords(bit_stream.to_bytes, version, ecl)

      canvas = Template.make_canvas(version)
      self.draw_codewords(canvas, codewords, version, ecl)
      mask, canvas = self.apply_best_mask(canvas, version, ecl)
      canvas.normalize

      MQR.new(version, ecl, canvas, mask)
    end

    # Returns a tuple of the optimized segments and Micro QR Code version
    # for the given text and error correction level.
    def determine_version_and_segments(text : String, ecl : ECC::Level)
      chars = text.chars
      segments, version = nil, nil

      # The number of the character count indicator bits which affect
      # the result of segmentation changes every version, so we calculate
      # the segments in each version and see if they fit in that version
      (Version::MIN..Version::MAX).each do |i|
        v = Version.new(i)
        char_modes = Segment::Segmenter.compute_char_modes(chars, v)
        segments = Segment::Segmenter.make_segments(text, char_modes)

        cap_bits = v.max_data_bits(ecl)
        begin
          used_bits = Segment.count_total_bits(segments, v)
        rescue e
          next if e.message == "Invalid segment"
          next if e.message == "Segment too long"
          raise e
        end

        # If it's within the bound, that is the optimal segmentation and version
        if used_bits <= cap_bits
          version = v
          break
        end
      end
      raise "Text too long" unless segments && version

      {segments, version}
    end

    protected def draw_codewords(canvas : Matrix(UInt8), codewords : Slice(UInt8), version : Version, ecl : ECC::Level)
      size = canvas.size
      data_length = codewords.size * 8

      i = 0
      upward = true     # Current filling direction
      base_x = size - 1 # Zig zag filling starts from bottom right
      while base_x > 0
        (0...size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : size - 1 - base_y
            next if canvas[x, y] & 0x80 > 0
            return if i >= data_length

            data_i = i >> 3
            if version == 1 && data_i == 2 ||
               version == 3 && ecl.low? && data_i == 10 ||
               version == 3 && ecl.medium? && data_i == 8
              bit = codewords[data_i].bit(3 - i & 3)
              i += 1
              i += 4 if i % 4 == 0
            else
              bit = codewords[data_i].bit(7 - i & 7)
              i += 1
            end

            canvas[x, y] = bit
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    protected def apply_best_mask(canvas : Matrix(UInt8), version : Version, ecl : ECC::Level)
      mask, best_canvas = nil, nil
      max_score = Int32::MIN

      4_u8.times do |i|
        c = canvas.clone
        msk = Mask.new(i)
        Template.draw_format_modules(c, msk, version, ecl)
        msk.apply_to(c)

        score = Mask.evaluate_score(c)
        if score > max_score
          mask = msk
          best_canvas = c
          max_score = score
        end
      end
      raise "Unable to set the mask" unless mask && best_canvas

      {mask, best_canvas}
    end
  end
end
