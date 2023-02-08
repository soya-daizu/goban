require "./rmqr/*"
require "./ecc/*"

module Goban
  # Object that represents an encoded rMQR Code symbol.
  struct RMQR
    # Version of the rMQR Code symbol. Version in QR Code does not refer to its revision,
    # but simply indicates the size format of the QR Code symbol.
    getter version : Version
    # Error correction level of the rMQR Code symbol.
    getter ecl : ECC::Level
    # Returns the canvas of the rMQR Code symbol. Canvas contains information about
    # each single module (pixel) in the symbol.
    getter canvas : Canvas
    # Width and height of the symbol.
    getter size : SymbolDimension

    enum SizingStrategy : UInt8
      MinimizeArea
      MinimizeWidth
      MinimizeHeight
    end

    protected def initialize(@version, @ecl, @canvas)
      @size = @version.symbol_size
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
      segments, version = Segment::Segmenter.segment_text_optimized_rmqr(text, ecl, strategy)
      self.encode_segments(segments, ecl, version)
    end

    # Creates a new rMQR Code object for the given data segments, error correction level, and
    # rMQR Code version that is large enough to contain all the data in the segments.
    #
    # See `QR.encode_segments` for more information.
    def self.encode_segments(segments : Array(Segment), ecl : ECC::Level, version : Version)
      raise "Unsupported EC Level" unless ecl.medium? || ecl.high?

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
      drawer.apply_mask
      drawer.canvas.normalize

      self.new(version, ecl, drawer.canvas)
    end

    # Prints the QR Code symbol as a text in the console. To generate the actual image file,
    # use `PNGExporter` or write your own exporter by reading each modules in `#canvas`.
    def print_to_console
      @canvas.print_to_console
    end
  end
end
