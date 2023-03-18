require "./abstract/*"
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

    # See `MQR::Encoder.encode_string`.
    def self.encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium)
      Encoder.encode_string(text, ecl)
    end

    # See `MQR::Encoder.encode_segments`.
    def self.encode_segments(segments : Array(Segment), ecl : ECC::Level, version : Version | Int)
      Encoder.encode_segments(segments, ecl, version)
    end
  end
end
