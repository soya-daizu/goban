module Goban::ECC
  module GF
    extend self

    EXP_TABLE = begin
      a = uninitialized UInt8[256]

      a[0] = 1
      (1..255).each do |i|
        v = a[i - 1].to_i * 2
        a[i] = (v >= 256 ? (v ^ 0x011d) : v).to_u8
      end

      a
    end

    LOG_TABLE = begin
      a = uninitialized UInt8[256]

      (0..255).each do |i|
        a[EXP_TABLE[i]] = i.to_u8
      end

      a
    end

    def exp(x : UInt8)
      EXP_TABLE[x]
    end

    def log(x : UInt8)
      raise InputError.new("Can't take log(0)") if x == 0
      LOG_TABLE[x]
    end

    def add_or_sub(x : UInt8, y : UInt8)
      x ^ y
    end

    def mul(x : UInt8, y : UInt8)
      return 0_u8 if x == 0 || y == 0
      EXP_TABLE[(LOG_TABLE[x].to_i + LOG_TABLE[y]) % 255]
    end

    def div(x : UInt8, y : UInt8)
      raise InputError.new("Division by 0") if y == 0
      return 0_u8 if x == 0
      EXP_TABLE[(LOG_TABLE[x].to_i + 255 - LOG_TABLE[y]) % 255]
    end

    def pow(x : UInt8, pow : UInt8)
      EXP_TABLE[(LOG_TABLE[x] * pow) % 255]
    end

    def inv(x : UInt8)
      raise InputError.new("Can't invert 0") if x == 0
      EXP_TABLE[255 - LOG_TABLE[x]]
    end
  end
end
