module Goban
  # An array data structure that holds bits.
  # Based on the `BitArray` object of the standard library.
  struct BitStream
    include Indexable::Mutable(Bool)
    include Comparable(BitStream)

    # Pointer to the underlying UInt8 representation.
    getter bits : Pointer(UInt8)
    # Size of the array.
    getter size : Int32
    # Current tail index of the writer. This increases as more bits are written.
    property write_pos = 0
    # Current tail index of the reader. This increases as more bits are read.
    property read_pos = 0
    # Whether this bit stream is read-only.
    getter read_only : Bool

    PAD0 = 0b1110_1100
    PAD1 = 0b0001_0001

    def initialize(size : Int)
      raise InputError.new("Negative bit stream size") if size < 0
      @size = size.to_i
      @bits = Pointer(UInt8).malloc(malloc_size, 0)
      @read_only = false
    end

    def initialize(bytes : Slice(UInt8))
      @size = bytes.size * 8
      @bits = bytes.to_unsafe
      @read_only = true
    end

    protected def append_segment_bits(segment : Segment, version : AbstractQR::Version)
      indicator = segment.mode.indicator(version)
      indicator_length = version.mode_indicator_length

      cci_bits = segment.char_count
      cci_bits_count = segment.mode.cci_bits_count(version)

      raise InternalError.new("Invalid segment") if !cci_bits_count
      raise InputError.new("Text too long") if @write_pos + indicator_length + cci_bits_count + segment.bit_size > size

      push_bits(indicator, indicator_length)
      push_bits(cci_bits, cci_bits_count)

      segment.produce_bits do |val, len|
        push_bits(val, len)
      end
    end

    protected def append_terminator_bits(version : AbstractQR::Version, ecl : ECC::Level)
      cap_bits = version.max_data_bits(ecl)
      case version
      when QR::Version
        base = 4
      when MQR::Version
        base = 3 + (version.to_i - 1) * 2
      when RMQR::Version
        base = 3
      else
        raise InternalError.new("Invalid QR version")
      end
      terminator_bits_size = Math.min(base, cap_bits - @write_pos)
      push_bits(0, terminator_bits_size)
    end

    protected def append_padding_bits(version : AbstractQR::Version)
      # Pad to the codeword boundary with zeros. In version M1 and M3, the data
      # capacity is not a multiple of 8 because the last data codeword is only
      # 4 bits long, so we must not write beyond the capacity here.
      push_bits(0, Math.min(-@write_pos % 8, @size - @write_pos))

      # Fill the remaining full codewords with the pad codewords. The shorter
      # last codeword of M1 and M3 (if left) stays as 0000.
      while @write_pos + 8 <= @size
        push_bits(PAD0, 8)
        push_bits(PAD1, 8) if @write_pos + 8 <= @size
      end
    end

    protected def push_bits(val : Int?, len : Int?)
      return if !val || !len
      return if len == 0

      raise InternalError.new("Too many bits to append") unless len.in?(0..31) && val >> len == 0
      raise InternalError.new("Can't write to a read-only bit stream") if read_only
      raise IndexError.new if @write_pos + len > @size

      # Write the bits from the most significant one, filling up the
      # remaining bits of the current byte each time. The buffer is zeroed
      # and only appended to, so the bits can simply be ORed in.
      val = val.to_u32
      remaining = len.to_i
      while remaining > 0
        free = 8 - (@write_pos & 7)
        count = Math.min(free, remaining)
        remaining -= count
        chunk = (val >> remaining) & ((1_u32 << count) - 1)
        @bits[@write_pos >> 3] |= (chunk << (free - count)).to_u8!
        @write_pos += count
      end
    end

    protected def read_bits(len : Int)
      raise InternalError.new("Too many bits to read (len: #{len}, size: #{@size}, read_pos: #{@read_pos})") unless len.in?(0..31) && @read_pos + len <= @size

      result = 0_u32
      len.times do |i|
        bit = self[@read_pos] ? 1 : 0
        result = (result << 1) | bit
        @read_pos += 1
      end

      result
    end

    protected def unsafe_fetch(index : Int)
      bit_idx, sub_idx = index.divmod(8)
      sub_idx = 7 - sub_idx
      (@bits[bit_idx] & (1 << sub_idx)) > 0
    end

    protected def unsafe_put(index : Int, value : Bool)
      bit_idx, sub_idx = index.divmod(8)
      sub_idx = 7 - sub_idx
      if value
        @bits[bit_idx] |= 1 << sub_idx
      else
        @bits[bit_idx] &= ~(1 << sub_idx)
      end
    end

    # Adds a value to the current tail of the array.
    private def push(value : Bool)
      raise InternalError.new("Can't write to a read-only bit stream") if read_only
      self[@write_pos] = value
      @write_pos += 1

      value
    end

    protected def to_bytes
      Slice(UInt8).new(@bits, malloc_size, read_only: true)
    end

    def inspect(io : IO)
      io << "Goban::BitStream(@write_pos=" << @write_pos
      io << ", @read_pos=" << @read_pos
      io << ", @bits=["
      idx = 0
      self.each_slice(4) do |bits|
        io << ' ' unless idx == 0
        bits.each do |bit|
          io << '\'' if idx == @write_pos || idx == @read_pos
          io << (bit ? '1' : '0')
          idx += 1
        end
      end
      io << "])"
    end

    def <=>(other : BitStream)
      min_size = Math.min(size, other.size)
      (0...min_size).each do |i|
        return nil if self[i] != other[i]
      end
      size <=> other.size
    end

    private def malloc_size
      (@size + 7) // 8
    end
  end
end
