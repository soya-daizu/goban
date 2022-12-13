# Goban

A fast and efficient QR Code encoder library written purely in Crystal. It uses significantly less heap allocations than other implementations in Crystal, and it is more feature-complete with support for Kanji mode encoding.

The encoder implementation is mostly independent of other implementations and is based on [ISO/IEC 18004:2015](https://www.iso.org/standard/62021.html), however the efficient text segmentation is made possible thanks to the following article: [Optimal text segmentation for QR Codes](https://www.nayuki.io/page/optimal-text-segmentation-for-qr-codes).

The name comes from the board game [Go](<https://en.wikipedia.org/wiki/Go_(game)>), which have inspired the QR Code inventor to come up with a fast and accurate matrix barcode to read. Goban is the name of the [Go board](https://en.wikipedia.org/wiki/Go_equipment#Board) in Japanese.

## Benchmark

Comparing op/s and heap allocations between Goban and [spider-gazelle/qr-code](https://github.com/spider-gazelle/qr-code)

```crystal
require "benchmark"
require "qr-code"
require "goban"

Benchmark.ips do |x|
  x.report("qr-code") { QR.new("Hello World!", level: :h) }
  x.report("goban") { Goban::QR.encode_string("Hello World!", Goban::ECC::Level::High) }
end
```

```
qr-code   3.39k (295.26µs) (± 1.40%)   149kB/op   2.13× slower
  goban   7.20k (138.80µs) (± 1.99%)  2.71kB/op        fastest
```

## Features

- [x] Encoding a sequence of text segments
  - [x] Numeric mode
  - [x] Alphanumeric mode
  - [x] Byte mode
  - [x] Kanji mode
- [x] Building optimized text segments from a string
- [x] Error correction coding using Reed-Solomon Codes
- [x] Data masking with all 8 mask patterns
- [x] Support for all QR Code versions from 1 to 40
- [] Structured append of symbols
- [] Micro QR Code (In development)
- [] rMQR Code (Not a part of ISO/IEC 18004:2015 standard)

Goban will not support generation of QR Code Model 1 symbols as it is considered obsolete.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     goban:
       github: soya-daizu/goban
   ```

2. Run `shards install`

## Usage

```crystal
require "goban"

qr = Goban::QR.encode_string("Hello World!", Goban::ECC::Level::Low)
qr.print_to_console
# => ██████████████  ████    ██  ██████████████
#    ██          ██    ██    ██  ██          ██
#    ██  ██████  ██  ██  ██  ██  ██  ██████  ██
#    ██  ██████  ██  ██    ██    ██  ██████  ██
#    ██  ██████  ██  ██████      ██  ██████  ██
#    ██          ██              ██          ██
#    ██████████████  ██  ██  ██  ██████████████
#                      ████
#    ████████    ██  ██  ██    ██    ██████  ██
#    ██████████    ██  ██    ██████████████  ██
#        ██    ████    ██    ████  ██      ████
#    ████  ██      ██████    ██    ██  ██  ██
#    ████  ██████████  ██████  ████          ██
#                    ████████    ████    ██  ██
#    ██████████████      ██    ████████
#    ██          ██    ██████████  ██  ████
#    ██  ██████  ██    ██  ██          ██████
#    ██  ██████  ██  ██  ██  ██  ██    ██████
#    ██  ██████  ██  ██████  ██    ██    ██
#    ██          ██  ██    ██  ████████      ██
#    ██████████████  ██    ██  ██████    ██
```

To generate a PNG image, add [stumpy_png](https://github.com/stumpycr/stumpy_png) as a dependency in your shard.yml, and `require "goban/exporters/png"` to use `PNGExporter`.

```crystal
require "goban/exporters/png"

qr = Goban::QR.encode_string("Hello World!")
puts "Exporting with targeted size: 500"
size = Goban::PNGExporter.export(qr, "output.png", 500)
puts "Actual QR Code size: #{size}"
```

See [API docs](https://soya-daizu.github.io/goban/Goban/QR.html) for more details.

## Contributing

1. Fork it (<https://github.com/soya-daizu/goban/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [soya_daizu](https://github.com/soya-daizu) - creator and maintainer
