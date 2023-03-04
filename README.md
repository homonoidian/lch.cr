# LCH.cr

> Implementation mostly copied from [chroma.js](https://github.com/gka/chroma.js)

A shard to convert LCH colors to RGB and RGB colors to LCH.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     lch:
       github: homonoidian/lch.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "lch"

LCH.rgb2lch(r: 123, g: 40, b: 123)         # {32.17, 55.27, 327.61}
LCH.lch2rgb(l: 32.17, c: 55.27, h: 327.61) # {123, 40, 123}
# or LCH.rgb2lch([123, 40, 123])
# or LCH.lch2rgb([32.17, 55.27, 327.61])
# or any other Indexable
```

Several other, related conversion methods are public, but `rgb2lch` and
`lch2rgb` are the main ones.

## Rough benchmark

```text
                        fast path 353.81M (  2.83ns) (± 4.35%)  0.0B/op         fastest
                       rgb to lch   5.69M (175.74ns) (± 0.90%)  0.0B/op   62.18× slower
              lch to rgb, in sRGB   9.63M (103.83ns) (± 1.00%)  0.0B/op   36.74× slower
lch to rgb with fitting into sRGB 486.06k (  2.06µs) (± 0.59%)  0.0B/op  727.92× slower
```

Your numbers may be different, but in general, fitting into sRGB will always be slower because doing this requires multiple conversions and a loop.

## Contributing

1. Fork it (<https://github.com/homonoidian/lch.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [Alexey Yurchenko](https://github.com/homonoidian) - creator and maintainer
