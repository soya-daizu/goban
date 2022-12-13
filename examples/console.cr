require "../src/goban"

qr = Goban::QR.encode_string("Hello World!", Goban::ECC::Level::Low)
puts qr.version
puts qr.ecl
qr.print_to_console

# Kanji mode also works!
qr = Goban::QR.encode_string("こんにちは、世界！", Goban::ECC::Level::Low)
puts qr.version
puts qr.ecl
qr.print_to_console
