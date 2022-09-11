struct Goban::QRCode
  struct Mask
    getter value : UInt8

    def initialize(@value)
      raise "Invalid mask number" if @value > 7
    end

    def apply_to(canvas : Canvas)
      proc = MASK_COMPUTATIONS[@value]
      canvas.size.times do |y|
        canvas.size.times do |x|
          next if canvas.is_module_reserved?(x, y)
          value = canvas.get_module(x, y) ^ proc.call(y, x)
          canvas.set_module(x, y, value)
        end
      end
    end

    def self.evaluate_score(canvas : Canvas)
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
          m3 = canvas.get_module(x, y + 1)
          m4 = canvas.get_module(x + 1, y + 1)

          score += 3 if m1 == m2 && m2 == m3 && m3 == m4
        end
      end

      score
    end

    private def self.compute_finder_score(canvas : Canvas, is_horizontal : Bool)
      pattern = {true, false, true, true, true, false, true}
      score = 0

      # In horizontal mode, i is y coordinate and j is x coordinate
      canvas.size.times do |i|
        (canvas.size - 7).times do |j|
          pattern_matches = (j...j + 7).all? do |k|
            value = is_horizontal ? canvas.get_module(k, i) : canvas.get_module(i, k)
            value == pattern[k - j]
          end
          next unless pattern_matches

          score += 40 if (j - 4...j).all? do |k|
                           value = is_horizontal ? canvas.get_module(k, i) : canvas.get_module(i, k)
                           value == false
                         end
          score += 40 if (j + 7...j + 11).all? do |k|
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
