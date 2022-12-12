require "./spec_helper"

module Goban
  describe QR do
    describe ".encode_string" do
      qr = QR.encode_string(SAMPLE_STR, QR::ECLevel::Medium)

      it "reports correct version" do
        qr.version.value.should eq(2)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(QR::ECLevel::Medium)
      end

      it "encodes properly" do
        qr.canvas.modules.should eq(SAMPLE_RESULT_MODS)
      end

      it "raises if text is too long" do
        long_str = String.build do |io|
          7090.times { io << '0' } # Numeric mode can contain upto 7089 characters
        end

        expect_raises(Exception, "Text too long") do
          QR.encode_string(long_str, QR::ECLevel::Low)
        end
      end
    end

    describe ".encode_segments" do
      qr = QR.encode_segments(SAMPLE_SEGS, QR::ECLevel::Medium, QR::Version.new(2))

      it "reports correct version" do
        qr.version.value.should eq(2)
      end

      it "reports correct ec level" do
        qr.ecl.should eq(QR::ECLevel::Medium)
      end

      it "encodes properly" do
        qr.canvas.modules.should eq(SAMPLE_RESULT_MODS)
      end
    end
  end
end
