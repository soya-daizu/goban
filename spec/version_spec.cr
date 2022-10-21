require "./spec_helper"

module Goban
  describe QRCode::Version do
    describe "#max_data_codewords" do
      it "reports correct codewords limit" do
        max = QRCode::Version.new(1).max_data_codewords(QRCode::ECLevel::Low)
        max.should eq(19)

        max = QRCode::Version.new(10).max_data_codewords(QRCode::ECLevel::High)
        max.should eq(122)

        max = QRCode::Version.new(27).max_data_codewords(QRCode::ECLevel::Medium)
        max.should eq(1128)

        max = QRCode::Version.new(40).max_data_codewords(QRCode::ECLevel::Quartile)
        max.should eq(1666)
      end
    end
  end
end
