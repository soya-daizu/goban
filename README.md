# Goban

A fast and efficient QR Code encoder library written purely in Crystal. It is significantly faster (5.33x) and uses fewer heap allocations (-94.63%) compared to the other implementation in Crystal ([spider-gazelle/qr-code](https://github.com/spider-gazelle/qr-code)), and it supports wider QR Code standard features such as Kanji mode encoding.

The implementation is based on [ISO/IEC 18004:2015](https://www.iso.org/standard/62021.html)/[JIS X 0510:2018](https://webdesk.jsa.or.jp/books/W11M0090/index/?bunsyo_id=JIS+X+0510%3A2018) standard and is independent of other implementations for the most part. However, the optimal text segmentation algorithm is made possible thanks to the following article: [Optimal text segmentation for QR Codes](https://www.nayuki.io/page/optimal-text-segmentation-for-qr-codes).

The name comes from the board game [Go](<https://en.wikipedia.org/wiki/Go_(game)>), which inspired the QR Code inventor to come up with a fast and accurate matrix barcode to read. 碁盤(Goban) literally means [Go board](https://en.wikipedia.org/wiki/Go_equipment#Board) in Japanese.

## Benchmark

Comparing it/s and heap allocations between Goban and [spider-gazelle/qr-code](https://github.com/spider-gazelle/qr-code):

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
qr-code   3.49k (286.18µs) (± 1.51%)   149kB/op   5.33× slower
  goban  18.61k ( 53.74µs) (± 1.81%)  8.08kB/op        fastest
```

## Features

- [x] Encoding a sequence of text segments
  - [x] Numeric mode
  - [x] Alphanumeric mode
  - [x] Byte mode
  - [x] Kanji mode
  - [ ] ECI mode
- [x] Building optimized text segments from a string
- [x] Error correction coding using Reed-Solomon Codes
- [x] Data masking with all 8 mask patterns
- [x] Support for all QR Code versions from 1 to 40
- [ ] Structured append of symbols
- [ ] Micro QR Code (In development)
- [ ] rMQR Code (Not a part of ISO/IEC 18004:2015 standard but planned)

Goban will not support the generation of QR Code Model 1 symbols as it is considered obsolete.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     goban:
       github: soya-daizu/goban
   ```

2. Run `shards install`

## Usage

A simple example to generate a QR Code for the given string and output to the console:

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

### Using exporters to generate a PNG and SVG image

To generate a PNG image, add [stumpy_png](https://github.com/stumpycr/stumpy_png) as a dependency in your shard.yml, and `require "goban/exporters/png"` to use `Goban::PNGExporter`:

```crystal
require "goban/exporters/png"

qr = Goban::QR.encode_string("Hello World!")
puts "Exporting with targeted size: 500"
size = Goban::PNGExporter.export(qr, "output.png", 500)
puts "Actual QR Code size: #{size}"
```

`Goban::SVGExporter` requires no external dependency and can be used like below:

```crystal
require "goban/exporters/svg"

qr = Goban::QR.encode_string("Hello World!")
# Get SVG string
puts Goban::SVGExporter.svg_string(qr, 4)
# or export as a file
Goban::SVGExporter.export(qr, "test.svg")
```

### About the automatic text segmentation

The `Goban::QR.encode_string()` method encodes a string to an optimized sequence of text segments where each segment is encoded in one of the following encoding modes:

| Mode | Supported Characters |
| --- | --- |
| Numeric | 0-9 |
| Alphanumeric | 0-9 A-Z \s $ % \* + - . / : |
| Byte | Any UTF-8 characters |
| Kanji | Any Shift-JIS characters |

The `Byte` mode supports the widest range of characters but it is inefficient and produces longer data bits, meaning that when comparing the two QR Code symbols, one encoded entirely in the `Byte` mode and the other encoded in the appropriate mode for each character\*, the former one can be more challenging to scan and decode than the other given that both symbols are printed in the same size.

\* Because each text segment includes additional header bits to indicate its encoding mode, simply encoding each character in the supported mode that has the smallest character set may not always produce the most optimal segments. Goban addresses this by using the technique of dynamic programming.

Finding out the optimal segmentation requires some processing, so if you are generating thousands of QR Codes with all the same limited sets of characters, you may want to hard-code the text segments and apply the characters to those to generate the QR Codes.

This can be done by using the `Goban::QR.encode_segments()` method, which is the lower-level method used by the `Goban::QR.encode_string()` method.

```crystal
segments = [
  Goban::Segment.kanji("こんにち"),
  Goban::Segment.byte("wa"),
  Goban::Segment.kanji("、世界！"),
  Goban::Segment.alphanumeric(" 123"),
]
# Note that when using this method, you have to manually assign the version (= size) of the QR Code.
qr = Goban::QR.encode_segments(segments, Goban::ECC::Level::Low, Goban::QR::Version.new(2))
```

The optimal segments and version to hard-code can be figured out by using the `Goban::Segment::Optimizer.make_optimized_segments()` method.

## API Documentations

The API docs for the current master branch are available from the link below:

[API docs](https://soya-daizu.github.io/goban/)

You may want to first look at the `Goban::QR` or one of the exporters (`Goban::PNGExporter` and `Goban::SVGExporters`) to understand how to use this library.

## Contributing

1. Fork it (<https://github.com/soya-daizu/goban/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [soya_daizu](https://github.com/soya-daizu) - creator and maintainer
