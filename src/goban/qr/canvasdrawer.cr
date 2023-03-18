struct Goban::QR < Goban::AbstractQR
  # Handles painting each QR Code modules on a canvas.
  module CanvasDrawer
    extend AbstractQR::CanvasDrawer

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - Finder patterns on each corner except bottom right
    # - Alignment patterns depending on the QR Code version
    # - Timing patterns in both directions
    protected def self.draw_function_patterns(canvas : Matrix(UInt8), version : Version)
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

    # Draws data bits from the given data codewords.
    protected def self.draw_data_codewords(canvas : Matrix(UInt8), data_codewords : Slice(UInt8))
      size = canvas.size
      data_length = data_codewords.size * 8

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

            bit = data_codewords[i >> 3].bit(7 - i & 7)
            canvas[x, y] = bit
            i += 1
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    # Test each mask patterns and apply one with the lowest (= best) score
    protected def self.apply_best_mask(canvas : Matrix(UInt8), ecl : ECC::Level)
      mask, best_canvas = nil, nil
      min_score = Int32::MAX

      8_u8.times do |i|
        c = canvas.clone
        msk = Mask.new(i)
        self.draw_format_modules(c, msk, ecl)
        msk.apply_to(c)

        score = Mask.evaluate_score(c)
        if score < min_score
          mask = msk
          best_canvas = c
          min_score = score
        end
      end
      raise "Unable to set the mask" unless mask && best_canvas

      {mask, best_canvas}
    end

    private def self.draw_version_modules(canvas : Matrix(UInt8), version : Version)
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

    protected def self.draw_format_modules(canvas : Matrix(UInt8), mask : Mask, ecl : ECC::Level)
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
