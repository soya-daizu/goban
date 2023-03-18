struct Goban::MQR < Goban::AbstractQR
  # Represents a mask pattern that can be applied to a canvas.
  struct Mask < AbstractQR::Mask
    MIN = 0_u8
    MAX = 3_u8

    MASK_PATTERNS = {
      ->(x : Int32, y : Int32) { y & 1 == 0 },
      ->(x : Int32, y : Int32) { (x // 3 + y // 2) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x * y) & 1) + (x * y) % 3) & 1 == 0 },
      ->(x : Int32, y : Int32) { (((x + y) & 1) + (x * y) % 3) & 1 == 0 },
    }

    {% begin %}
      FORMAT_BITS = {
        {% for mask in (MIN..MAX) %}
          {
            {% for symbol_num in (0..7) %}
              {% data = symbol_num << 2 | mask %}
              {% rem = data %}
              {% for _ in (0..9) %}
                {% rem = (rem << 1) ^ ((rem >> 9) * 0x537) %}
              {% end %}
              {% bits = (data << 10 | rem) ^ 0x4445 %}

              {{bits}},
            {% end %}
          },
        {% end %}
      }
    {% end %}

    def initialize(value)
      raise "Invalid mask number" unless (MIN..MAX).includes?(value)
      @value = value.to_u8
      @mask_pattern = MASK_PATTERNS[@value]
    end

    protected def get_format_bits(ver : Version, ecl : ECC::Level)
      FORMAT_BITS[@value][ver.get_symbol_num(ecl)]
    end

    # Evaluate penalty score for the given canvas.
    # It assumes that one of the masks is applied to the canvas.
    protected def self.evaluate_score(canvas : Matrix(UInt8))
      s1, s2 = 0, 0
      canvas.size.times do |i|
        s1 += canvas[canvas.size - 1, i] & 1
        s2 += canvas[i, canvas.size - 1] & 1
      end

      if s1 <= s2
        s1 * 16 + s2
      else
        s2 * 16 + s1
      end
    end
  end
end
