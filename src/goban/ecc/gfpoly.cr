module Goban::ECC
  struct GFPoly
    include Indexable::Mutable(UInt8)

    getter data : Slice(UInt8)

    delegate size, to: @data
    delegate unsafe_fetch, to: @data
    delegate unsafe_put, to: @data

    def initialize(@data, truncate = true)
      return unless truncate
      first_non_zero = @data.index { |v| v != 0 }
      if !first_non_zero
        @data = Slice[0_u8]
      elsif first_non_zero > 0
        @data = @data[first_non_zero, @data.size - first_non_zero]
      end
    end

    def self.zero
      GFPoly.new(Slice[0_u8])
    end

    def self.one
      GFPoly.new(Slice[1_u8])
    end

    def self.build_mono(degree : Int, coeff : UInt8)
      return self.zero if coeff == 0
      coeffs = Slice(UInt8).new(degree + 1)
      coeffs[0] = coeff

      GFPoly.new(coeffs)
    end

    def is_zero?
      self[0] == 0
    end

    def degree
      self.size - 1
    end

    def get_coeff(degree : Int)
      self[self.size - 1 - degree]
    end

    def eval(x : Int)
      y = self[0]
      (1...self.size).each do |i|
        y = GF.mul(y, x.to_u8) ^ self[i]
      end

      y
    end

    def scale(x : Int)
      result = @data.map do |v|
        GF.mul(v, x)
      end

      GFPoly.new(result)
    end

    def add_or_sub(other : Indexable(UInt8))
      return other if self.is_zero?
      return self if other.is_zero?

      smaller, larger = self, other
      smaller, larger = other, self if smaller.size > larger.size
      size_diff = larger.size - smaller.size

      result = Slice(UInt8).new(larger.size) do |i|
        next larger[i] if i < size_diff
        GF.add_or_sub(smaller[i - size_diff], larger[i])
      end

      GFPoly.new(result)
    end

    def mul(other : Indexable(UInt8))
      result = Slice(UInt8).new(self.size + other.size - 1)

      self.size.times do |i|
        other.size.times do |j|
          result[i + j] ^= GF.mul(self[i], other[j])
        end
      end

      GFPoly.new(result)
    end

    def div(other : Indexable(UInt8))
      raise InputError.new("Division by 0") if other.is_zero?

      result = Slice(UInt8).new(self.size + other.size - 1)
      @data.copy_to(result)

      self.size.times do |i|
        coeff = result[i]
        next if coeff == 0
        (1...other.size).each do |j|
          next if other[j] == 0
          result[i + j] ^= GF.mul(other[j], coeff)
        end
      end

      {
        GFPoly.new(result[0, self.size], truncate: false),
        GFPoly.new(result[self.size, result.size - self.size], truncate: false),
      }
    end

    def div2(other : Indexable(UInt8))
      raise InputError.new("Division by 0") if other.is_zero?

      quotient = GFPoly.zero
      remainder = self

      denominator_leading_term = other.get_coeff(other.degree)
      inv_denominator_leading_term = GF.inv(denominator_leading_term)

      while remainder.degree >= other.degree && !remainder.is_zero?
        degree_diff = remainder.degree - other.degree
        scale = GF.mul(remainder.get_coeff(remainder.degree), inv_denominator_leading_term)

        iter_quotient = GFPoly.build_mono(degree_diff, scale)
        term = other.mul(iter_quotient)

        quotient = quotient.add_or_sub(iter_quotient)
        remainder = remainder.add_or_sub(term)
      end

      {quotient, remainder}
    end
  end
end
