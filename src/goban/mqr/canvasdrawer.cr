struct Goban::MQR < Goban::AbstractQR
  # Handles painting each Micro QR Code modules on a canvas.
  module CanvasDrawer
    extend AbstractQR::CanvasDrawer

    # Draws all function patterns on the canvas.
    # The function patterns are:
    #
    # - Finder patterns on the top left corner
    # - Timing patterns in both directions
    protected def self.draw_function_patterns(canvas : Matrix(UInt8))
      canvas[0, 0, 9, 9] = 0xc0

      self.draw_pattern(canvas, 0, 0, FINDER_PATTERN, 7)

      self.draw_timing_pattern(canvas, 0, canvas.size - 8)
    end

    # Draws data bits from the given data codewords.
    protected def self.draw_data_codewords(canvas : Matrix(UInt8), data_codewords : Slice(UInt8),
                                           version : Version, ecl : ECC::Level)
      size = canvas.size
      data_length = data_codewords.size * 8

      i = 0
      upward = true     # Current filling direction
      base_x = size - 1 # Zig zag filling starts from bottom right
      while base_x > 0
        (0...size).reverse_each do |base_y|
          (0..1).each do |alt|
            x = base_x - alt
            y = upward ? base_y : size - 1 - base_y
            next if canvas[x, y] & 0x80 > 0
            return if i >= data_length

            data_i = i >> 3
            if version == 1 && data_i == 2 ||
               version == 3 && ecl.low? && data_i == 10 ||
               version == 3 && ecl.medium? && data_i == 8
              bit = data_codewords[data_i].bit(3 - i & 3)
              i += 1
              i += 4 if i % 4 == 0
            else
              bit = data_codewords[data_i].bit(7 - i & 7)
              i += 1
            end

            canvas[x, y] = bit
          end
        end

        upward = !upward
        base_x -= 2
      end
    end

    # Test each mask patterns and apply one with the lowest (= best) score
    protected def self.apply_best_mask(canvas : Matrix(UInt8), version : Version, ecl : ECC::Level)
      mask, best_canvas = nil, nil
      max_score = Int32::MIN

      4_u8.times do |i|
        c = canvas.clone
        msk = Mask.new(i)
        self.draw_format_modules(c, msk, version, ecl)
        msk.apply_to(c)

        score = Mask.evaluate_score(c)
        if score > max_score
          mask = msk
          best_canvas = c
          max_score = score
        end
      end
      raise "Unable to set the mask" unless mask && best_canvas

      {mask, best_canvas}
   end

    protected def self.draw_format_modules(canvas : Matrix(UInt8), mask : Mask, ver : Version, ecl : ECC::Level)
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
