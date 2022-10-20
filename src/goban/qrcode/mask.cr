struct Goban::QRCode
  # Represents a mask pattern that can be applied to a canvas.
  struct Mask
    # Mask identifier. Valid values are integers from 0 to 7.
    getter value : UInt8

    def initialize(@value)
      raise "Invalid mask number" if @value > 7
    end

    # Apply mask to the given canvas.
    # Call this method again to reverse the applied mask.
    protected def apply_to(canvas : Canvas)
      canvas.size.times do |y|
        canvas.size.times do |x|
          next if canvas.module_reserved?(x, y)
          invert = case @value
                   when 0; (x + y) % 2 == 0
                   when 1; y % 2 == 0
                   when 2; x % 3 == 0
                   when 3; (x + y) % 3 == 0
                   when 4; (x // 3 + y // 2) % 2 == 0
                   when 5; (x * y) % 2 + (x * y) % 3 == 0
                   when 6; ((x * y) % 2 + (x * y) % 3) % 2 == 0
                   when 7; ((x + y) % 2 + (x * y) % 3) % 2 == 0
                   else    raise "Invalid mask number"
                   end

          value = canvas.get_module(x, y) ^ invert
          canvas.set_module(x, y, value)
        end
      end
    end

    # Evaluate penalty score for the given canvas.
    # It assumes that one of the masks is applied to the canvas.
    protected def self.evaluate_score(canvas : Canvas)
      s1_a = self.compute_adjacent_score(canvas, true)
      s1_b = self.compute_adjacent_score(canvas, false)
      s2 = self.compute_block_score(canvas)
      s3_a = self.compute_finder_score(canvas, true)
      s3_b = self.compute_finder_score(canvas, false)
      s4 = self.compute_balance_score(canvas)

      s1_a + s1_b + s2 + s3_a + s3_b + s4
    end

    private def self.compute_adjacent_score(canvas : Canvas, is_horizontal : Bool)
      score = 0

      # In horizontal mode, i is y coordinate and j is x coordinate
      canvas.size.times do |i|
        last_value = nil
        same_count = 1

        canvas.size.times do |j|
          value = is_horizontal ? canvas.get_module(j, i) : canvas.get_module(i, j)
          if value == last_value
            same_count += 1
            next unless j == canvas.size - 1
          end

          last_value = value
          score += same_count - 2 if same_count >= 5
          same_count = 1
        end
      end

      score
    end

    private def self.compute_block_score(canvas : Canvas)
      score = 0

      (canvas.size - 1).times do |y|
        (canvas.size - 1).times do |x|
          m1 = canvas.get_module(x, y)
          m2 = canvas.get_module(x + 1, y)
          next unless m1 == m2
          m3 = canvas.get_module(x, y + 1)
          m4 = canvas.get_module(x + 1, y + 1)

          score += 3 if m2 == m3 && m3 == m4
        end
      end

      score
    end

    private def self.compute_finder_score(canvas : Canvas, is_horizontal : Bool)
      pattern = {true, false, true, true, true, false, true}
      score = 0

      # In horizontal mode, i is y coordinate and j is x coordinate
      canvas.size.times do |i|
        (0..canvas.size - 7).each do |j|
          pattern_matches = (j..j + 6).all? do |k|
            value = is_horizontal ? canvas.get_module(k, i) : canvas.get_module(i, k)
            value == pattern[k - j]
          end
          next unless pattern_matches

          score += 40 if (j - 4..j - 1).all? do |k|
                           next false unless k > 0
                           value = is_horizontal ? canvas.get_module(k, i) : canvas.get_module(i, k)
                           value == false
                         end
          score += 40 if (j + 7..j + 10).all? do |k|
                           next false unless k <= canvas.size - 1
                           value = is_horizontal ? canvas.get_module(k, i) : canvas.get_module(i, k)
                           value == false
                         end
        end
      end

      score
    end

    private def self.compute_balance_score(canvas : Canvas)
      dark_modules = canvas.modules.count(true)
      total_modules = canvas.size ** 2
      ratio = dark_modules / total_modules * 100
      distance = (ratio.to_i - 50).abs
      distance // 5 * 10
    end
  end
end
