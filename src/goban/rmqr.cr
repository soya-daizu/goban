require "./abstract/*"
require "./rmqr/*"
require "./ecc/*"

module Goban
  # Object that represents an encoded rMQR Code symbol.
  struct RMQR < AbstractQR
    # Version of the rMQR Code symbol. Version in QR Code does not refer to its revision,
    # but simply indicates the size format of the QR Code symbol.
    getter version : Version
    # Error correction level of the rMQR Code symbol.
    getter ecl : ECC::Level
    # Returns the canvas of the rMQR Code symbol. Canvas contains information about
    # each single module (pixel) in the symbol.
    getter canvas : Matrix(UInt8)
    # Width and height of the symbol.
    getter size : SymbolDimension

    protected def initialize(@version, @ecl, @canvas)
      @size = @version.symbol_size
    end

    # See `RMQR::Encoder.encode_string`.
    def self.encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium, strategy : Encoder::SizingStrategy = Encoder::SizingStrategy::MinimizeArea)
      Encoder.encode_string(text, ecl, strategy)
    end

    # See `RMQR::Encoder.encode_segments`.
    def self.encode_segments(segments : Array(Segment), ecl : ECC::Level, version : Version | VersionValue)
      Encoder.encode_segments(segments, ecl, version)
    end
  end
end
