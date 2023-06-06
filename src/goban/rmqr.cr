require "./abstract/*"
require "./rmqr/*"
require "./ecc/*"

module Goban
  # Object that represents an encoded rMQR Code symbol.
  struct RMQR < AbstractQR
    extend Encoder

    # Version of the rMQR Code symbol. Version in QR Code does not refer to its revision,
    # but simply indicates the size format of the QR Code symbol.
    getter version : Version
    # Error correction level of the rMQR Code symbol.
    getter ecl : ECC::Level
    # Content text segments of the QR Code symbol.
    getter segments : Array(Segment)
    # Returns the canvas of the rMQR Code symbol. Canvas contains information about
    # each single module (pixel) in the symbol.
    getter canvas : Canvas(UInt8)
    # Width and height of the symbol.
    getter size : SymbolDimension

    protected def initialize(@version, @ecl, @segments, @canvas)
      @size = @version.symbol_size
    end
  end
end
