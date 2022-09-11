require "./goban/*"

segments = Goban::Segment.numeric("2222")
qr = Goban::QRCode.encode_segments([segments], Goban::QRCode::ECLevel::Low)
puts qr.version
puts qr.ecl
qr.print_to_console

