require "../src/goban"

text = "こんにちwa、世界！ 123"
puts "Encoding text: #{text}"
qr = Goban::QR.encode_string(text)
decoded = Goban::QR::Decoder.decode_to_string(qr.canvas)
puts "Decoded text: #{decoded}"
