require "./spec_helper"

module Goban
  characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789".chars

  describe QR do
    describe ".encode_string" do
      it "passes fuzz test" do
        100.times do
          str = String.build do |io|
            (14..2331).sample.times { io << characters.sample }
          end
          decoded = nil
          begin
            qr = QR.encode_string(str, ECC::Level::Medium)
            decoded = QR.decode_to_string(qr.canvas)
          rescue e
            decoded = e
          end
          decoded.should eq(str)
        end
      end
    end
  end

  describe MQR do
    describe ".encode_string" do
      it "passes fuzz test" do
        100.times do
          str = String.build do |io|
            (9..13).sample.times { io << characters.sample }
          end
          decoded = nil
          begin
            qr = MQR.encode_string(str, ECC::Level::Medium)
            decoded = MQR.decode_to_string(qr.canvas)
          rescue e
            decoded = e
          end
          decoded.should eq(str)
        end
      end
    end
  end

  describe RMQR do
    describe ".encode_string" do
      it "passes fuzz test" do
        100.times do
          str = String.build do |io|
            (5..150).sample.times { io << characters.sample }
          end
          decoded = nil
          begin
            qr = RMQR.encode_string(str, ECC::Level::Medium)
            decoded = RMQR.decode_to_string(qr.canvas)
          rescue e
            decoded = e
          end
          decoded.should eq(str)
        end
      end
    end
  end
end
