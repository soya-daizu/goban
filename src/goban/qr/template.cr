struct Goban::QR < Goban::AbstractQR
  # Handles painting each QR Code modules on a canvas.
  module Template
    extend self
    include AbstractQR::Template

    # Creates a new canvas with all the function patterns drawn for the given version.
    protected def make_canvas(version : Version)
      size = version.symbol_size
      canvas = Canvas(UInt8).new(size, size, 0)
      self.draw_function_patterns(canvas, version)

      canvas
    end

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - Finder patterns on each corner except bottom right
    # - Alignment patterns depending on the QR Code version
    # - Timing patterns in both directions
    protected def draw_function_patterns(canvas : Canvas(UInt8), version : Version)
      size = canvas.size

      self.draw_pattern(canvas, 0, 0, FINDER_PATTERN, 7)
      self.draw_pattern(canvas, size - 7, 0, FINDER_PATTERN, 7)
      self.draw_pattern(canvas, 0, size - 7, FINDER_PATTERN, 7)

      # Reserving areas for the finder patterns and format info at once
      # as they belong to the same adjacent square area
      canvas[0, 7, 9, 2] = 0xc0
      canvas[7, 0, 2, 7] = 0xc0
      canvas[size - 8, 0, 1, 7] = 0xc0
      canvas[size - 8, 7, 8, 2] = 0xc0
      canvas[0, size - 8, 8, 1] = 0xc0
      canvas[7, size - 7, 2, 7] = 0xc0

      positions = version.alignment_pattern_positions
      ali_pat_count = positions.size
      ali_pat_count.times do |i|
        ali_pat_count.times do |j|
          next if i == 0 && j == 0 ||
                  i == 0 && j == ali_pat_count - 1 ||
                  i == ali_pat_count - 1 && j == 0
          x, y = positions[i], positions[j]

          self.draw_pattern(canvas, x - 2, y - 2, ALIGNMENT_PATTERN, 5)
        end
      end

      self.draw_timing_pattern(canvas, 6, size - 16)

      self.draw_version_modules(canvas, version)

      canvas[8, canvas.size - 8] = 0xc1
    end

    private def draw_version_modules(canvas : Canvas(UInt8), version : Version)
      return if version < 7
      bits = version.get_version_bits

      (0...18).each do |i|
        bit = (bits >> i & 1).to_u8 | 0xc0
        x = i // 3
        y = canvas.size - 11 + i % 3
        canvas[x, y] = bit
        canvas[y, x] = bit
      end
    end

    protected def draw_format_modules(canvas : Canvas(UInt8), mask : Mask, ecl : ECC::Level)
      bits = mask.get_format_bits(ecl)

      (0...8).each do |i|
        bit = (bits >> i & 1).to_u8 | 0xc0
        pos = i >= 6 ? i + 1 : i
        canvas[8, pos] = bit
        pos = canvas.size - 1 - i
        canvas[pos, 8] = bit
      end

      (0...7).each do |i|
        bit = (bits >> 14 - i & 1).to_u8 | 0xc0
        pos = i >= 6 ? i + 1 : i
        canvas[pos, 8] = bit
        pos = canvas.size - 1 - i
        canvas[8, pos] = bit
      end
    end
  end
end
