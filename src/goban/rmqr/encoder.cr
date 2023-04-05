struct Goban::RMQR < Goban::AbstractQR
  module Encoder
    enum SizingStrategy : UInt8
      MinimizeArea
      MinimizeWidth
      MinimizeHeight
    end

    # Creates a new Micro QR Code object for the given string, error correction level, and sizing strategy.
    #
    # Unlike regular QR Codes and Micro QR Codes, rMQR Codes has different sizes in width and height,
    # which means that there can be multiple versions that are optimal in terms of capacity.
    # `SizingStrategy` is used to prioritize one version than the other based on whether you want the symbol
    # to be smaller in total area, width, or height. By default, it tries to balance the width and height,
    # keeping the total area as small as possible.
    #
    # See `QR.encode_string` for more information.
    def self.encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium, strategy : SizingStrategy = SizingStrategy::MinimizeArea)
      segments, version = self.determine_version_and_segments(text, ecl, strategy)
      self.encode_segments(segments, ecl, version)
    end

    # Creates a new rMQR Code object for the given data segments, error correction level, and
    # rMQR Code version that is large enough to contain all the data in the segments.
    #
    # See `QR.encode_segments` for more information.
    def self.encode_segments(segments : Array(Segment), ecl : ECC::Level, version : Version | VersionValue)
      raise "Unsupported EC Level" unless ecl.medium? || ecl.high?

      version = Version.new(version.value)
      bit_stream = BitStream.new(version.max_data_bits(ecl))
      segments.each do |segment|
        bit_stream.append_segment_bits(segment, version)
      end
      bit_stream.append_terminator_bits(version, ecl)
      bit_stream.append_padding_bits(version)

      data_codewords = ECC::RSInflator.inflate_codewords(bit_stream.to_bytes, version, ecl)

      size = version.symbol_size
      canvas = Matrix(UInt8).new(size.width, size.height, 0)
      CanvasDrawer.draw_function_patterns(canvas, version, ecl)
      CanvasDrawer.draw_data_codewords(canvas, data_codewords)
      mask, canvas = CanvasDrawer.apply_mask(canvas)
      canvas.normalize

      RMQR.new(version, ecl, canvas)
    end

    # Returns a tuple of the optimized segments and rMQR Code version
    # for the given text and error correction level.
    def self.determine_version_and_segments(text : String, ecl : ECC::Level, strategy : SizingStrategy) : Tuple(Array(Segment), RMQR::Version)
      chars = text.chars
      segments, version = nil, nil

      # The number of the character count indicator bits which affect
      # the result of segmentation changes every version, so we calculate
      # the segments in each version and see if they fit in that version
      Version::ORDERED[strategy.value].each do |vv|
        v = Version.new(vv)
        char_modes = Segment::Segmenter.compute_char_modes(chars, v)
        segments = Segment::Segmenter.make_segments(text, char_modes)

        cap_bits = v.max_data_bits(ecl)
        begin
          used_bits = Segment.count_total_bits(segments, v)
        rescue e
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
