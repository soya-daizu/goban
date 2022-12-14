require "./spec_helper"

module Goban
  describe QR do
    describe ".encode_string" do
      qr = QR.encode_string(SAMPLE_STR, ECC::Level::Medium)

      it "reports correct version" do
        qr.version.value.should eq(2)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(ECC::Level::Medium)
      end

      it "encodes properly" do
        rows = convert_canvas(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_QR)
      end

      it "raises if text is too long" do
        long_str = String.build do |io|
          7090.times { io << '0' } # Numeric mode can contain upto 7089 characters
        end

        expect_raises(Exception, "Text too long") do
          QR.encode_string(long_str, ECC::Level::Low)
        end
      end
    end

    describe ".encode_segments" do
      qr = QR.encode_segments(SAMPLE_SEGS, ECC::Level::Medium, 2)

      it "reports correct version" do
        qr.version.value.should eq(2)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(ECC::Level::Medium)
      end

      it "encodes properly" do
        rows = convert_canvas(qr.canvas)
        rows.should eq(SAMPLE_RESULT_MODS_QR)
      end
    end
  end
end
