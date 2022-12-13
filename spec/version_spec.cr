require "./spec_helper"

module Goban
  describe QR::Version do
    describe "#max_data_codewords" do
      it "reports correct codewords limit" do
        max = QR::Version.new(1).max_data_codewords(ECC::Level::Low)
        max.should eq(19)

        max = QR::Version.new(10).max_data_codewords(ECC::Level::High)
        max.should eq(122)

        max = QR::Version.new(27).max_data_codewords(ECC::Level::Medium)
        max.should eq(1128)

        max = QR::Version.new(40).max_data_codewords(ECC::Level::Quartile)
        max.should eq(1666)
      end
    end
  end
end
