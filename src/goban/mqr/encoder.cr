struct Goban::MQR < Goban::AbstractQR
  module Encoder
    # Creates a new Micro QR Code object for the given string and error correction level.
    #
    # Note that Micro QR Codes have limited EC levels you can select depending on the length
    # of the text. In version M1, the EC level passed will just be ignored.
    #
    # See `QR.encode_string` for more information.
    def self.encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium)
      segments, version = self.determine_version_and_segments(text, ecl)
      self.encode_segments(segments, ecl, version)
    end

    # Creates a new Micro QR Code object for the given data segments, error correction level, and
    # Micro QR Code version that is large enough to contain all the data in the segments.
    #
    # See `QR.encode_segments` for more information.
    def self.encode_segments(segments : Array(Segment), ecl : ECC::Level, version : Version | Int)
      version = Version.new(version.to_i)
      bit_stream = BitStream.new(version.max_data_bits(ecl))
      segments.each do |segment|
        bit_stream.append_segment_bits(segment, version)
      end
      bit_stream.append_terminator_bits(version, ecl)
      bit_stream.append_padding_bits(version)

      data_codewords = ECC::RSGenerator.add_ec_codewords(bit_stream.to_bytes, version, ecl)

      size = version.symbol_size
      canvas = Matrix(UInt8).new(size, size, 0)
      CanvasDrawer.draw_function_patterns(canvas)
      CanvasDrawer.draw_data_codewords(canvas, data_codewords, version, ecl)
      mask, canvas = CanvasDrawer.apply_best_mask(canvas, version, ecl)
      canvas.normalize

      MQR.new(version, ecl, canvas, mask)
    end

    # Returns a tuple of the optimized segments and Micro QR Code version
    # for the given text and error correction level.
    def self.determine_version_and_segments(text : String, ecl : ECC::Level) : Tuple(Array(Segment), Version)
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
  end
end
