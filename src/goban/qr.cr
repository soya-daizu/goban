require "./qr/*"
require "./ecc/*"

module Goban
  # Object that represents an encoded QR Code symbol.
  struct QR
    # Version of the QR Code symbol. Version in QR Code does not refer to its revision,
    # but simply indicates the size format of the QR Code symbol.
    getter version : Version
    # Error correction level of the QR Code symbol.
    getter ecl : ECC::Level
    # Returns the canvas of the QR Code symbol. Canvas contains information about
    # each single module (pixel) in the symbol.
    getter canvas : Canvas
    # Length of a side in the symbol.
    getter size : Int32
    # Mask applied to this QR Code symbol.
    getter mask : Mask

    protected def initialize(@version, @ecl, @canvas, @mask)
      @size = @version.symbol_size
    end

    # Creates a new QR Code object for the given string and error correction level.
    # Setting a higher error correction level makes the QR Code symbol mode resistant
    # to loss of pixels, but it requires more redundant bits, resulting in a larger
    # symbol size.
    # Use `PNGExporter` to generate the PNG image from the QR Code object generated.
    #
    # ```
    # qr = Goban::QR.encode_string("Hello World!", Goban::ECC::Level::Low)
    # qr.print_to_console
    # # => ██████████████  ████    ██  ██████████████
    # #    ██          ██    ██    ██  ██          ██
    # #    ██  ██████  ██  ██  ██  ██  ██  ██████  ██
    # #    ██  ██████  ██  ██    ██    ██  ██████  ██
    # #    ██  ██████  ██  ██████      ██  ██████  ██
    # #    ██          ██              ██          ██
    # #    ██████████████  ██  ██  ██  ██████████████
    # #                      ████
    # #    ████████    ██  ██  ██    ██    ██████  ██
    # #    ██████████    ██  ██    ██████████████  ██
    # #        ██    ████    ██    ████  ██      ████
    # #    ████  ██      ██████    ██    ██  ██  ██
    # #    ████  ██████████  ██████  ████          ██
    # #                    ████████    ████    ██  ██
    # #    ██████████████      ██    ████████
    # #    ██          ██    ██████████  ██  ████
    # #    ██  ██████  ██    ██  ██          ██████
    # #    ██  ██████  ██  ██  ██  ██  ██    ██████
    # #    ██  ██████  ██  ██████  ██    ██    ██
    # #    ██          ██  ██    ██  ████████      ██
    # #    ██████████████  ██    ██  ██████    ██
    # ```
    #
    # QR Code data under the hood is encoded in one or more encoding types, such as Numeric,
    # Alphanumeric, Byte, and Kanji. Each encoding type has a different set of characters
    # supported. While Byte mode can express arbitrary types of data (usually interpreted as UTF-8
    # text, thus it can express any Unicode characters), it often uses more bits to represent a single
    # codepoint compared to other encoding types which have a limited set of characters supported,
    # resulting in larger data size and a more challenging QR Code to scan.
    #
    # This string encoding uses an algorithm to figure out the best segmentation of the encoding
    # types for the given string to make the resulting data size as small as possible. Here are the
    # examples:
    #
    # ```
    # # These examples are the optimal segmentations when the EC Level is Medium.
    # # Note that the Segment object shown in these examples are not the actual Segment object used
    # # in the Goban's codebase but they are just pseudo objects.
    #
    # "0123456789" # => [Segment("0123456789", mode: Numeric)]
    # "ABCDEF"     # => [Segment("ABCDEF", mode: Alphanumeric)]
    # "012345A"    # => [Segment("012345A", mode: Alphanumeric)]
    # "0123456A"   # => [Segment("0123456", mode: Numeric), Segment("A", mode: Alphanumeric)]
    # "こんにちwa、世界！ 123"
    # # => [
    # #   Segment("こんにち", mode: Kanji),
    # #   Segment("wa", mode: Byte),
    # #   Segment("、世界！", mode: Kanji),
    # #   Segment(" 123", mode: Alphanumeric)
    # # ]
    # ```
    #
    # If the type of characters used in your data strings is always the same, you may want to consider
    # building data segments by yourself so that Goban doesn't have to do extra processing to figure
    # it out every single time. See `#encode_segments` for how to create QR Codes by manually creating
    # encoding segments.
    def self.encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium)
      segments, version = Segment::Segmenter.segment_text_optimized(text, ecl)
      self.encode_segments(segments, ecl, version)
    end

    # Creates a new QR Code object for the given data segments, error correction level, and QR Code
    # version that is large enough to contain all the data in the segments. Note that this method
    # does not check the data length before encoding, so it will just raise `Index out of bounds`
    # error if the data does not fit within the given version.
    # Use `PNGExporter` to generate the PNG image from the QR Code object generated.
    #
    # ```
    # segments = [
    #   Goban::Segment.alphanumeric("HELLO WORLD"),
    #   Goban::Segment.byte("!"),
    # ]
    # qr = Goban::QR.encode_segments(segments, Goban::ECC::Level::Low, Goban::QR::Version.new(1))
    # qr.print_to_console
    # # => ██████████████    ██  ████  ██████████████
    # #    ██          ██    ██████    ██          ██
    # #    ██  ██████  ██  ████  ████  ██  ██████  ██
    # #    ██  ██████  ██    ██  ██    ██  ██████  ██
    # #    ██  ██████  ██      ██  ██  ██  ██████  ██
    # #    ██          ██          ██  ██          ██
    # #    ██████████████  ██  ██  ██  ██████████████
    # #                    ████  ████
    # #    ██████  ████████████████  ████      ██
    # #        ██    ██                    ██      ██
    # #      ████  ██  ████████    ██████  ████
    # #      ██  ██  ██  ████████    ██  ██  ██████
    # #        ██  ██████  ██      ██  ██████  ██  ██
    # #                    ██  ████  ██        ██  ██
    # #    ██████████████  ████████    ████  ████
    # #    ██          ██  ████  ████    ██  ██
    # #    ██  ██████  ██  ████████    ██████████████
    # #    ██  ██████  ██        ██  ██████      ██
    # #    ██  ██████  ██  ██      ██  ████  ██    ██
    # #    ██          ██  ████████          ██  ████
    # #    ██████████████  ██      ██  ████        ██
    # ```
    #
    # When constructing your own segments, note that it may not result in the segments that has the
    # shortest data length even if for each character in the source string you choose an encoding type
    # with the smallest character set that supports that supports it.
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

    # Prints the QR Code symbol as a text in the console. To generate the actual image file,
    # use `PNGExporter` or write your own exporter by reading each modules in `#canvas`.
    def print_to_console
      @canvas.print_to_console
    end
  end
end
