struct Goban::QR < Goban::AbstractQR
  module Encoder
    extend self

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
    # it out every single time.
    #
    # The optimal segments and version to hard-code can be figured out by manually executing
    # `Segment::Segmenter.segment_text_optimized_qr`. You can hard-code the segments and version based on
    # its response, and use `QR.encode_segments` to create QR Codes using that segments and version.
    def encode_string(text : String, ecl : ECC::Level = ECC::Level::Medium)
      segments, version = self.determine_version_and_segments(text, ecl)
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
      self.draw_codewords(canvas, codewords)
      mask, canvas = self.apply_best_mask(canvas, ecl)
      canvas.normalize

      QR.new(version, ecl, segments, canvas, mask)
    end

    # Returns a tuple of the optimized segments and QR Code version for the given text and error correction level.
    def determine_version_and_segments(text : String, ecl : ECC::Level)
      chars = text.chars
      segments, version = nil, nil

      # The number of the character count indicator bits which affect
      # the result of segmentation changes at the version 1, 10, and 27,
      # so we first calculate the segments at those boundaries and reduce
      # the version number later
      {1..9, 10..26, 27..40}.each do |group|
        v = QR::Version.new(group.end)
        char_modes = Segment::Segmenter.compute_char_modes(chars, v)
        segments = Segment::Segmenter.make_segments(text, char_modes)

        cap_bits = v.max_data_bits(ecl)
        begin
          used_bits = Segment.count_total_bits(segments, v)
        rescue e : InputError
          next if e.message == "Segment too long"
          raise e
        end

        # If it's within the bound, that is the optimal segmentation
        # Now find the smallest version in that group that can hold the data
        if used_bits <= cap_bits
          group.each do |i|
            sml_v = QR::Version.new(i)
            sml_cap_bits = sml_v.max_data_bits(ecl)

            if used_bits <= sml_cap_bits
              version = sml_v
              break
            end
          end

          break
        end
      end
      raise InputError.new("Text too long") unless segments && version

      {segments, version}
    end

    protected def draw_codewords(canvas : Canvas(UInt8), codewords : Slice(UInt8))
      size = canvas.size
      data_length = codewords.size * 8

      i = 0
      upward = true     # Current filling direction
      base_x = size - 1 # Zig zag filling starts from bottom right
      while base_x > 0
        base_x = 5 if base_x == 6 # Skip vertical timing pattern

        (0...size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : size - 1 - base_y
            next if canvas[x, y] & 0x80 > 0
            return if i >= data_length

            bit = codewords[i >> 3].bit(7 - i & 7)
            canvas[x, y] = bit
            i += 1
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    protected def apply_best_mask(canvas : Canvas(UInt8), ecl : ECC::Level)
      mask, best_canvas = nil, nil
      min_score = Int32::MAX

      {% if flag?(:preview_mt) %}
        channel = Channel(Tuple(Canvas(UInt8), UInt8, Int32)).new(8)
        8_u8.times do |i|
          spawn do
            c = canvas.clone
            msk = Mask.new(i)
            Template.draw_format_modules(c, msk, ecl)
            msk.apply_to(c)

            score = Mask.evaluate_score(c)
            channel.send({c, i, score})
          end
        end
        8.times do
          c, i, score = channel.receive
          if score < min_score
            mask = Mask.new(i)
            best_canvas = c
            min_score = score
          end
        end
      {% else %}
        8_u8.times do |i|
          c = canvas.clone
          msk = Mask.new(i)
          Template.draw_format_modules(c, msk, ecl)
          msk.apply_to(c)

          score = Mask.evaluate_score(c)
          if score < min_score
            mask = msk
            best_canvas = c
            min_score = score
          end
        end
      {% end %}
      raise InternalError.new("Unable to set the mask") unless mask && best_canvas

      {mask, best_canvas}
    end
  end
end
