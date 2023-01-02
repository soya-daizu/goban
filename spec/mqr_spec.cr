require "./spec_helper"

module Goban
  describe MQR do
    describe ".encode_segments" do
      qr = MQR.encode_segments(SAMPLE_SEGS_2, ECC::Level::Low, 3)

      it "reports correct version" do
        qr.version.value.should eq(3)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(ECC::Level::Low)
      end

      it "encodes properly" do
        rows = convert_canvas(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_MQR)
      end
    end
  end
end
