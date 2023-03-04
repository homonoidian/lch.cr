# Methods for LCH to RGB and RGB to LCH conversion.
#
# Implementation mostly copied from [chroma.js](https://github.com/gka/chroma.js)
#
# D65 standard referent is used during conversion.
#
# CIELCH to sRGB conversion may be lossy. sRGB to CIELCH shouldn't
# be lossy, but might still fall prey to precision errors.
#
# ```
# LCH.rgb2lch(123, 40, 123)         # {32.17, 55.27, 327.61}
# LCH.lch2rgb(32.17, 55.27, 327.61) # {123, 40, 123}
# ```
module LCH
  extend self

  private D65_X = 0.950470
  private D65_Y =      1.0
  private D65_Z = 1.088830

  private LAB_T0 = 4 / 29
  private LAB_T1 = 6 / 29
  private LAB_T2 = 3 * LAB_T1 ** 2
  private LAB_T3 = LAB_T1 ** 3

  #
  #   LCH -> RGB
  #

  @[AlwaysInline]
  private def lab_xyz(t)
    t > LAB_T1 ? t * t * t : LAB_T2 * (t - LAB_T0)
  end

  @[AlwaysInline]
  private def xyz_srgb(n)
    n <= 0.00304 ? 12.92 * n : 1.055 * n**(1 / 2.4) - 0.055
  end

  # Returns an RGB tuple for the given CIELAB color.
  def lab2srgb(l, a, b)
    y = (l + 16) / 116
    x = y + a / 500
    z = y - b / 200

    x = D65_X * lab_xyz(x)
    y = D65_Y * lab_xyz(y)
    z = D65_Z * lab_xyz(z)

    r = xyz_srgb(3.2404542 * x - 1.5371385 * y - 0.4985314 * z) # D65 -> sRGB
    g = xyz_srgb(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z)
    b = xyz_srgb(0.0556434 * x - 0.2040259 * y + 1.0572252 * z)

    {r, g, b}
  end

  # Returns a CIELAB tuple for the given LCH color.
  def lch2lab(l, c, h)
    h = h * Math::PI / 180
    {l, Math.cos(h) * c, Math.sin(h) * c}
  end

  private def lch2srgb_norm(l, c, h)
    lab2srgb *lch2lab(l, c, h)
  end

  # The two methods below are copied from tabatkins's commit at:
  #
  # https://github.com/LeaVerou/css.land/pull/3/commits/d2ec6bdb80317358e2e2e5826b01e87130afd238
  #
  # I'm too dumb for all this math stuff so these are pretty
  # mach copy-pastes, just a bit Crystal-ized.

  # Returns RGB if the given LCH color is in the sRGB gamut.
  # Otherwise, returns nil.
  private def lch_as_srgb?(l, c, h)
    ε = 0.000005 # error compensation
    r, g, b = lch2srgb_norm(l, c, h)
    if r.in?(-ε..1 + ε) && g.in?(-ε..1 + ε) && b.in?(-ε..1 + ε)
      {r, g, b}
    end
  end

  # Returns an R, G, B tuple for the given LCH (CIELch) color.
  #
  # The lightness component *l*, percents, is clamped to (and
  # should be in) the range [0; 100].
  #
  # The chroma component *c* is clamped to (and should be in)
  # the range [0; 145].
  #
  # The resulting R, G, B components are in the range [0; 255].
  def lch2rgb(l : Number, c : Number, h : Number) : {Int32, Int32, Int32}
    if rgb = lch_as_srgb?(l, c, h)
      r, g, b = rgb
    else
      hi_c = c
      lo_c = 0
      c /= 2

      while hi_c - lo_c > 0.0001
        if lch_as_srgb?(l, c, h)
          lo_c = c
        else
          hi_c = c
        end
        c = (hi_c + lo_c)/2
      end

      r, g, b = lch2srgb_norm(l, c, h)
    end

    {(255 * r).round.to_i.clamp(0..255), # clamp just to be sure!
     (255 * g).round.to_i.clamp(0..255),
     (255 * b).round.to_i.clamp(0..255)}
  end

  # Converts the first three items in *lch* to RGB.
  #
  # Assumes the three first items are `Number`-typed L, C, H
  # values, correspondingly.
  def lch2rgb(lch : Indexable) : {Int32, Int32, Int32}
    lch2rgb(lch[0], lch[1], lch[2])
  end

  #
  #   RGB -> LCH
  #

  @[AlwaysInline]
  private def rgb_xyz(n)
    (n /= 255) <= 0.04045 ? n / 12.92 : ((n + 0.055) / 1.055)**2.4
  end

  @[AlwaysInline]
  private def xyz_lab(t)
    t > LAB_T3 ? Math.cbrt(t) : t / LAB_T2 + LAB_T0
  end

  # Returns a CIELch L, C, H tuple for the given CIELAB color.
  def lab2lch(l, a, b)
    c = Math.sqrt(a ** 2 + b ** 2)
    h = (Math.atan2(b, a) * 180 / Math::PI + 360) % 360
    {l, c, h}
  end

  # Returns a CIEXYZ X, Y, Z tuple for the given RGB color.
  def rgb2xyz(r, g, b)
    r, g, b = rgb_xyz(r), rgb_xyz(g), rgb_xyz(b)

    x = xyz_lab((0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / D65_X)
    y = xyz_lab((0.2126729 * r + 0.7151522 * g + 0.0721750 * b) / D65_Y)
    z = xyz_lab((0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / D65_Z)

    {x, y, z}
  end

  # Returns a CIELAB L, a, b tuple for the given RGB color.
  def rgb2lab(r, g, b)
    x, y, z = rgb2xyz(r, g, b)
    l = 116 * y - 16
    {l < 0 ? 0.0 : l, 500 * (x - y), 200 * (y - z)}
  end

  # Returns an L, C, H tuple for the given RGB color.
  #
  # *r*, *g*, and *b* are clamped between [0; 255].
  #
  # The resulting lightness component L is in percents, in range
  # [0; 100], rounded to two digits after the decimal place.
  #
  # The resulting chroma component C is in range [0; 145], rounded
  # to two digits after the decimal place.
  #
  # The resulting hue component H is in degress, in range [0; 360],
  # rounded to two digits after the decimal place.
  def rgb2lch(r : Int, g : Int, b : Int) : {Float64, Float64, Float64}
    r = r.clamp(0..255)
    g = g.clamp(0..255)
    b = b.clamp(0..255)

    case {r, g, b} # Some fast paths.
    when {0, 0, 0}       then return {0.0, 0.0, 0.0}
    when {255, 0, 0}     then return {54.0, 105.0, 40.0}
    when {0, 255, 0}     then return {87.82, 113.32, 134.38}
    when {0, 0, 255}     then return {29.57, 131.0, 301.36}
    when {255, 255, 255} then return {100.0, 0.0, 0.0}
    end

    l, c, h = lab2lch *rgb2lab(r, g, b)

    {l.round(2), c.round(2), h.round(2)}
  end

  # Converts the first three items in *rgb* to LCH.
  #
  # Assumes the three first items are `Int`-typed R, G, B
  # values, correspondingly.
  def rgb2lch(rgb : Indexable) : {Float64, Float64, Float64}
    rgb2lch(rgb[0], rgb[1], rgb[2])
  end
end
