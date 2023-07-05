require "./spec_helper"

module Goban
  describe ECC::RSDeflator do
    describe ".deflate_codewords" do
      it "corrects codewords with errors up to ecc_codewords/2 in length" do
        codewords = Slice[
          16_u8, 166_u8, 200_u8, 225_u8, 12_u8, 78_u8, 86_u8, 168_u8,
          106_u8, 222_u8, 110_u8, 200_u8, 20_u8, 0_u8, 234_u8, 236_u8,
          141_u8, 17_u8, 247_u8, 236_u8, 161_u8, 17_u8, 237_u8, 236_u8,
          200_u8, 17_u8, 197_u8, 236_u8, 64_u8, 17_u8, 197_u8, 236_u8,
          102_u8, 17_u8, 211_u8, 150_u8, 11_u8, 200_u8, 174_u8, 126_u8,
          107_u8, 215_u8, 20_u8, 252_u8, 68_u8, 242_u8, 237_u8, 9_u8,
          28_u8, 216_u8, 249_u8, 201_u8, 141_u8, 216_u8, 62_u8, 90_u8,
          210_u8, 208_u8, 215_u8, 78_u8, 129_u8, 19_u8, 68_u8, 122_u8,
          80_u8, 173_u8, 228_u8, 21_u8, 34_u8, 102_u8,
        ]
        corrupted = codewords.dup

        version = QR::Version.new(3)
        ecl = ECC::Level::Quartile
        ecc_codewords = ECC::EC_CODEWORDS_PER_BLOCK_QR[ecl.to_s][version.to_i] * ECC::EC_BLOCKS_QR[ecl.to_s][version.to_i]
        (ecc_codewords // 2).times do |i|
          corrupted[i] = Random.rand(256).to_u8
        end

        result = ECC::RSDeflator.deflate_codewords(corrupted, version, ecl)
        result.should eq(Slice[
          16_u8, 200_u8, 12_u8, 86_u8, 106_u8, 110_u8, 20_u8, 234_u8,
          141_u8, 247_u8, 161_u8, 237_u8, 200_u8, 197_u8, 64_u8, 197_u8,
          102_u8, 166_u8, 225_u8, 78_u8, 168_u8, 222_u8, 200_u8, 0_u8,
          236_u8, 17_u8, 236_u8, 17_u8, 236_u8, 17_u8, 236_u8, 17_u8,
          236_u8, 17_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8,
          0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8,
          0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8,
          0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8,
          0_u8, 0_u8, 0_u8, 0_u8, 0_u8, 0_u8,
        ])
      end
    end
  end
end
