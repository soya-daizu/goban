require "./spec_helper"

def convert_bit_stream(bit_stream : Goban::BitStream)
  String.build do |io|
    bit_stream.each do |bit|
      io << (bit ? '1' : '0')
    end
  end
end

module Goban
  describe BitStream do
    it "builds data bits properly" do
      v = QR::Version.new(1)
      ecl = ECC::Level::Low
      bit_stream = BitStream.new(v.max_data_bits(ecl))
      bit_stream.append_segment_bits(Segment.numeric("0123456789"), v)
      bit_stream.append_terminator_bits(v, ecl)
      bit_stream.append_padding_bits(v)

      bit_str = convert_bit_stream(bit_stream)
      bit_str.should eq("00010000001010000000110001010110011010100110100100000000111011000001000111101100000100011110110000010001111011000001000111101100000100011110110000010001")

      byte_str = bit_stream.to_bytes.map(&.to_s(16, precision: 2)).join(' ')
      byte_str.should eq("10 28 0c 56 6a 69 00 ec 11 ec 11 ec 11 ec 11 ec 11 ec 11")
    end

    it "appends bits across byte boundaries" do
      chunks = [{0b1, 1}, {0b0110, 4}, {0x1ff, 9}, {0, 3}, {0x5a5a5a5, 27}, {0b10, 2}, {0x7fffffff, 31}]
      bit_stream = BitStream.new(chunks.sum(&.[1]))
      chunks.each { |val, len| bit_stream.push_bits(val, len) }

      expected = chunks.join { |val, len| val.to_s(2, precision: len) }
      convert_bit_stream(bit_stream).should eq(expected)
      bit_stream.write_pos.should eq(expected.size)
    end

    it "raises when appending beyond its size" do
      bit_stream = BitStream.new(10)
      bit_stream.push_bits(0x1ff, 9)
      expect_raises(IndexError) { bit_stream.push_bits(0b11, 2) }
    end
  end
end
