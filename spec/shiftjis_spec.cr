require "./spec_helper"

module Goban
  describe ShiftJIS do
    it "has the table sorted by the code point without duplicates" do
      code_points = ShiftJIS::TABLE.each_slice(2).map(&.[0]).to_a
      code_points.each_cons_pair { |a, b| (a < b).should be_true }
    end

    describe ".encode?" do
      it "returns the Shift JIS code of the code point" do
        ShiftJIS.encode?(0x3000).should eq(0x8140)
        ShiftJIS.encode?('点'.ord).should eq(0x935F)
        ShiftJIS.encode?('茗'.ord).should eq(0xE4AA)
        ShiftJIS.encode?(0x005C).should eq(0x815F)
        ShiftJIS.encode?(0xFFE5).should eq(0x818F)
      end

      it "returns nil for the code points not in the table" do
        ShiftJIS.encode?(-1).should be_nil
        ShiftJIS.encode?('a'.ord).should be_nil
        ShiftJIS.encode?(0xFFFF).should be_nil
        ShiftJIS.encode?(0x10000).should be_nil
        ShiftJIS.encode?('😀'.ord).should be_nil
      end
    end
  end

  describe "UNICODE_SHIFTJIS_TABLE" do
    it "has every entry of ShiftJIS::TABLE" do
      UNICODE_SHIFTJIS_TABLE.size.should eq(ShiftJIS::TABLE.size // 2)
      UNICODE_SHIFTJIS_TABLE.each do |code_point, sjis|
        ShiftJIS.encode?(code_point).should eq(sjis)
      end
    end
  end
end
