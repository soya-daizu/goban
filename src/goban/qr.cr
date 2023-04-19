require "./abstract/*"
require "./qr/*"
require "./ecc/*"

module Goban
  # Object that represents an encoded QR Code symbol.
  struct QR < AbstractQR
    extend Encoder
    extend Decoder

    # Version of the QR Code symbol. Version in QR Code does not refer to its revision,
    # but simply indicates the size format of the QR Code symbol.
    getter version : Version
    # Error correction level of the QR Code symbol.
    getter ecl : ECC::Level
    # Content text segments of the QR Code symbol.
    getter segments : Array(Segment)
    # Returns the canvas of the QR Code symbol. Canvas contains information about
    # each single module (pixel) in the symbol.
    getter canvas : Matrix(UInt8)
    # Length of a side in the symbol.
    getter size : Int32
    # Mask applied to this QR Code symbol.
    getter mask : Mask

    protected def initialize(@version, @ecl, @segments, @canvas, @mask)
      @size = @version.symbol_size
    end
  end
end
