struct Goban::QRCode
  struct Mask
    getter value : UInt8

    def initialize(@value)
      raise "Invalid mask number" if @value > 7
    end

    def apply_to(modules : Array(Array(Bool)), reserved_modules : Array(Array(Bool)))
      proc = MASK_COMPUTATIONS[@value]
      modules.size.times do |y|
        modules.size.times do |x|
          next if reserved_modules[y][x]
          modules[y][x] ^= proc.call(y, x)
        end
      end
    end

    def self.evaluate_score(modules : Array(Array(Bool)))
      s1_a = self.compute_adjacent_score(modules, true)
      s1_b = self.compute_adjacent_score(modules, false)
      s2 = self.compute_block_score(modules)
      s3_a = self.compute_finder_score(modules, true)
      s3_b = self.compute_finder_score(modules, false)
      s4 = self.compute_balance_score(modules)
      puts "#{s1_a} #{s1_b} #{s2} #{s3_a} #{s3_b} #{s4}"

      s1_a + s1_b + s2 + s3_a + s3_b + s4
    end

    private def self.compute_adjacent_score(modules : Array(Array(Bool)), is_horizontal : Bool)
      score = 0

      # In horizontal mode, i is y coordinate and j is x coordinate
      modules.size.times do |i|
        if is_horizontal
          get_proc = ->(k : Int32) { modules[i][k] }
        else
          get_proc = ->(k : Int32) { modules[k][i] }
        end
        last_value = nil
        same_count = 1

        modules.size.times do |j|
          value = get_proc.call(j)
          if value == last_value
            same_count += 1
            next unless j == modules.size - 1
          end

          last_value = value
          score += same_count - 2 if same_count >= 5
          same_count = 1
        end
      end

      score
    end

    private def self.compute_block_score(modules : Array(Array(Bool)))
      score = 0

      (modules.size - 1).times do |y|
        (modules.size - 1).times do |x|
          m1 = modules[y][x]
          m2 = modules[y][x + 1]
          m3 = modules[y + 1][x]
          m4 = modules[y + 1][x + 1]

          score += 3 if m1 == m2 && m2 == m3 && m3 == m4
        end
      end

      score
    end

    private def self.compute_finder_score(modules : Array(Array(Bool)), is_horizontal : Bool)
      pattern = {true, false, true, true, true, false, true}
      score = 0

      # In horizontal mode, i is y coordinate and j is x coordinate
      modules.size.times do |i|
        (modules.size - 7).times do |j|
          if is_horizontal
            get_proc = ->(k : Int32) { modules[i][k] }
          else
            get_proc = ->(k : Int32) { modules[k][i] }
          end

          pattern_matches = (j...j + 7).all? do |k|
            get_proc.call(k) == pattern[k - j]
          end
          next unless pattern_matches

          check_proc = ->(k : Int32) do
            (0...modules.size).includes?(k) && get_proc.call(k) == false
          end
          score += 40 if (j - 4...j).all? { |k| check_proc.call(k) }
          score += 40 if (j + 7...j + 11).all? { |k| check_proc.call(k) }
        end
      end

      score
    end

    private def self.compute_balance_score(modules : Array(Array(Bool)))
      dark_modules = modules.sum(&.count(true))
      total_modules = modules.size ** 2
      ratio = dark_modules / total_modules * 100
      distance = (ratio.to_i - 50).abs
      distance // 5 * 10
    end
  end
end
