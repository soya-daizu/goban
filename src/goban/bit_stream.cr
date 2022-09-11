module Goban
  struct BitStream
    include Indexable::Mutable(Bool)

    getter bits : Pointer(UInt8)
    getter size : Int32
    getter tail_idx = 0

    PAD0 = 0b1110_1100
    PAD1 = 0b0001_0001

    def initialize(size : Int)
      raise "Negative bit stream size: #{size}" if size < 0
      @size = size.to_i
      @bits = Pointer(UInt8).malloc(malloc_size, 0)
    end

    def append_segment_bits(segment : Segment, version : QRCode::Version)
      append_bits(segment.mode.to_i, 4)
      append_bits(segment.char_count, segment.mode.cci_bits_size(version))
      append_bit_stream(segment.bit_stream)
    end

    def append_bit_stream(bs : BitStream)
      bs.each do |bit|
        push(bit)
      end
    end

    def append_terminator_bits(version : QRCode::Version, ecl : QRCode::ECLevel)
      cap_bits = version.max_data_codewords(ecl) * 8
      terminator_bits_size = Math.min(4, cap_bits - @tail_idx)
      append_bits(0, terminator_bits_size)
    end

    def append_padding_bits
      while @tail_idx % 8 != 0
        push(false)
      end

      while @tail_idx < @size
        append_bits(PAD0, 8)
        append_bits(PAD1, 8) if @tail_idx < @size
      end
    end

    def append_bits(val : Int, len : Int)
      raise "Value out of range" unless (0..31).includes?(len) && val >> len == 0
      (len - 1).downto(0) do |i|
        push((val >> i).to_u8! & 1 != 0)
      end
    end

    def to_bytes
      results = Slice(UInt8).new(malloc_size)
      byte_value = 0_u8
      each_with_index do |bit, idx|
        bit = bit ? 1 : 0
        byte_value = (byte_value << 1) | bit
        results[idx // 8] = byte_value if idx % 8 == 7
      end
      results[@size // 8] = byte_value << (8 - (@size % 8)) if @size % 8 != 0

      results
    end

    def unsafe_fetch(index : Int) : Bool
      bit_idx, sub_idx = index.divmod(8)
      (@bits[bit_idx] & (1 << sub_idx)) > 0
    end

    def unsafe_put(index : Int, value : Bool)
      bit_idx, sub_idx = index.divmod(8)
      if value
        @bits[bit_idx] |= 1 << sub_idx
      else
        @bits[bit_idx] &= ~(1 << sub_idx)
      end
    end

    def push(value : Bool)
      bit_idx, sub_idx = bit_idx_and_sub_idx(@tail_idx)
      if value
        @bits[bit_idx] |= 1 << sub_idx
      else
        @bits[bit_idx] &= ~(1 << sub_idx)
      end
      @tail_idx += 1

      value
    end

    def to_s(io : IO)
      io << "Goban::BitStream(@tail_idx=" << @tail_idx
      io << ", @bits=["
      idx = 0
      each_slice(4) do |bits|
        io << ' ' unless idx == 0
        bits.each do |bit|
          io << '\'' if idx == @tail_idx
          io << (bit ? '1' : '0')
          idx += 1
        end
      end
      io << "])"
    end

    private def bit_idx_and_sub_idx(idx)
      bit_idx_and_sub_idx(idx) { raise IndexError.new }
    end

    private def bit_idx_and_sub_idx(idx)
      idx = check_index_out_of_bounds(idx) do
        return yield
      end
      idx.divmod(8)
    end

    private def malloc_size
      (@size + 7) // 8
    end
  end
end
