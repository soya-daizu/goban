require "./spec_helper"

module Goban
  describe BitStream do
    it "builds data bits properly" do
      v = QR::Version.new(1)
      ecl = ECC::Level::Low
      bit_stream = BitStream.new(v.max_data_codewords(ecl) * 8)
      bit_stream.append_segment_bits(Segment.numeric("0123456789"), v)
      bit_stream.append_terminator_bits(v, ecl)
      bit_stream.append_padding_bits

      bit_str = convert_bit_stream(bit_stream)
      bit_str.should eq("00010000001010000000110001010110011010100110100100000000111011000001000111101100000100011110110000010001111011000001000111101100000100011110110000010001")

      byte_str = bit_stream.to_bytes.map(&.to_s(16)).join(' ')
      byte_str.should eq("10 28 c 56 6a 69 0 ec 11 ec 11 ec 11 ec 11 ec 11 ec 11")
    end
  end
end
