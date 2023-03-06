require "./mqr/*"
require "./ecc/*"

module Goban
  # Object that represents an encoded Micro QR Code symbol.
  struct MQR < AbstractQR
    # Version of the Micro QR Code symbol. Version in QR Code does not refer to its revision,
    # but simply indicates the size format of the QR Code symbol.
    getter version : Version
    # Error correction level of the Micro QR Code symbol.
    getter ecl : ECC::Level
    # Returns the canvas of the Micro QR Code symbol. Canvas contains information about
    # each single module (pixel) in the symbol.
    getter canvas : Matrix(UInt8)
    # Length of a side in the symbol.
    getter size : Int32
    # Mask applied to this Micro QR Code symbol.
    getter mask : Mask

    protected def initialize(@version, @ecl, @canvas, @mask)
      @size = @version.symbol_size
    end

    # Creates a new Micro QR Code object for the given string and error correction level.
    #
    # Note that Micro QR Codes have limited EC levels you can select depending on the length
    # of the text. In version M1, the EC level passed will just be ignored.
    #
    # See `QR.encode_string` for more information.
    def self.encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium)
      segments, version = Segment::Segmenter.segment_text_optimized_mqr(text, ecl)
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

      drawer = CanvasDrawer.new(version, ecl)
      drawer.draw_function_patterns
      drawer.draw_data_codewords(data_codewords)
      mask = drawer.apply_best_mask
      drawer.canvas.normalize

      self.new(version, ecl, drawer.canvas, mask)
    end
  end
end
