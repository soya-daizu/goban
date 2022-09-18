require "../src/goban"

qr = Goban::QRCode.encode_string("Hello World!", Goban::QRCode::ECLevel::Low)
puts qr.version
puts qr.ecl
qr.print_to_console

# Kanji mode also works!
qr = Goban::QRCode.encode_string("こんにちは、世界！", Goban::QRCode::ECLevel::Low)
puts qr.version
puts qr.ecl
qr.print_to_console
