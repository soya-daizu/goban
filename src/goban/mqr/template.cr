struct Goban::MQR < Goban::AbstractQR
  # Handles painting each Micro QR Code modules on a canvas.
  module Template
    extend self
    include AbstractQR::Template

    # Creates a new canvas canvas with all the function patterns drawn for the given version.
    protected def make_canvas(version : Version)
      size = version.symbol_size
      canvas = Canvas(UInt8).new(size, size, 0)
      self.draw_function_patterns(canvas)

      canvas
    end

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - Finder patterns on the top left corner
    # - Timing patterns in both directions
    protected def draw_function_patterns(canvas : Canvas(UInt8))
      canvas[0, 0, 9, 9] = 0xc0

      self.draw_pattern(canvas, 0, 0, FINDER_PATTERN, 7)

      self.draw_timing_pattern(canvas, 0, canvas.size - 8)
    end

    protected def draw_format_modules(canvas : Canvas(UInt8), mask : Mask, ver : Version, ecl : ECC::Level)
      bits = mask.get_format_bits(ver, ecl)

      (0...8).each do |i|
        bit = (bits >> i & 1).to_u8 | 0xc0
        pos = i + 1
        canvas[8, pos] = bit
      end

      (0...7).each do |i|
        bit = (bits >> 14 - i & 1).to_u8 | 0xc0
        pos = i + 1
        canvas[pos, 8] = bit
      end
    end
  end
end
