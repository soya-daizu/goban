struct Goban::QR < Goban::AbstractQR
  # Represents a mask pattern that can be applied to a canvas.
  struct Mask < AbstractQR::Mask
    MIN = 0_u8
    MAX = 7_u8

    MASK_PATTERNS = {
      ->(x : Int32, y : Int32) { (x + y) & 1 == 0 },
      ->(x : Int32, y : Int32) { y & 1 == 0 },
      ->(x : Int32, y : Int32) { x % 3 == 0 },
      ->(x : Int32, y : Int32) { (x + y) % 3 == 0 },
      ->(x : Int32, y : Int32) { (x // 3 + y // 2) & 1 == 0 },
      ->(x : Int32, y : Int32) { ((x * y) & 1) + (x * y) % 3 == 0 },
      ->(x : Int32, y : Int32) { (((x * y) & 1) + (x * y) % 3) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x + y) & 1) + (x * y) % 3) & 1 == 0 },
    }

    {% begin %}
      FORMAT_BITS = {
        {% for mask in (MIN..MAX) %}
          {
            {% for ecl in ECC::Level.constants %}
              {% ecl_value = ECC::Level.constant(ecl) %}
              {% data = 0_i32 + ecl_value << 3 | mask %}
              {% rem = data %}
              {% for _ in (0..9) %}
                {% rem = (rem << 1) ^ ((rem >> 9) * 0x537) %}
              {% end %}
              {% bits = (data << 10 | rem) ^ 0x5412 %}

              {{ecl.id}}: {{bits}},
            {% end %}
          },
        {% end %}
      }
    {% end %}

    def initialize(value)
      raise InputError.new("Invalid mask number") unless (MIN..MAX).includes?(value)
      @value = value.to_u8
      @mask_pattern = MASK_PATTERNS[@value]
    end

    protected def get_format_bits(ecl : ECC::Level)
      FORMAT_BITS[@value][ecl.to_s]
    end

    # Evaluate penalty score for the given canvas.
    # It assumes that one of the masks is applied to the canvas.
    protected def self.evaluate_score(canvas : Matrix(UInt8))
      s1_a, s3_a, s2, dark_count = self.compute_score_h(canvas)
      s1_b, s3_b = self.compute_score_v(canvas)
      s4 = self.compute_balance_score(dark_count, canvas.size)

      # puts "#{s1_a} + #{s1_b} + #{s2} + #{s3_a} + #{s3_b} + #{s4}"
      s1_a + s1_b + s2 + s3_a + s3_b + s4
    end

    private macro compute_score(is_horizontal)
      adj_score, fin_score = 0, 0
      {% if is_horizontal %}
        blk_score = 0
        dark_count = 0
      {% end %}

      # In horizontal mode, i is y coordinate and j is x coordinate
      canvas.size.times do |i|
        buffer = 0b000_0000_0000_u16
        last_value = nil
        same_count = 1

        canvas.size.times do |j|
          {% if is_horizontal %}
            value = canvas[j, i] & 1
            dark_count += value
          {% else %}
            value = canvas[i, j] & 1
          {% end %}

          buffer = ((buffer << 1) | value) & 0b111_1111_1111

          # Finder pattern score
          if j >= 10 && (buffer == 0b000_0101_1101 || buffer == 0b101_1101_0000)
            fin_score += 40
          end

          if value == last_value
            same_count += 1

            {% if is_horizontal %}
              # Block score
              if same_count >= 2 && i != canvas.size - 1
                blk_score += 3 if value == canvas[j - 1, i + 1] & 1 &&
                                  value == canvas[j, i + 1] & 1
              end
            {% end %}

            next unless j == canvas.size - 1
          end
          last_value = value

          # Adjacent score
          adj_score += same_count - 2 if same_count >= 5
          same_count = 1
        end
      end

      {
        adj_score,
        fin_score,
        {% if is_horizontal %}
        blk_score,
        dark_count,
        {% end %}
      }
    end

    private def self.compute_score_h(canvas : Matrix(UInt8))
      compute_score(true)
    end

    private def self.compute_score_v(canvas : Matrix(UInt8))
      compute_score(false)
    end

    private def self.compute_balance_score(dark_count : Int, size : Int)
      total_modules = size ** 2
      ratio = dark_count / total_modules * 100
      distance = (ratio.to_i - 50).abs
      distance // 5 * 10
    end
  end
end
