require "./spec_helper"

describe LCH do
  it "converts some rgb to lch" do
    LCH.rgb2lch(123, 40, 123).should eq({32.17, 55.27, 327.61})
    LCH.rgb2lch(0, 0, 0).should eq({0, 0, 0})
    LCH.rgb2lch(255, 255, 255).should eq({100, 0, 0})
  end

  it "clamps when converting to lch" do
    LCH.rgb2lch(-1000, -1000, -1000).should eq({0, 0, 0})
    LCH.rgb2lch(1000, 1000, 1000).should eq({100, 0, 0})
  end

  it "converts some lch to rgb" do
    LCH.lch2rgb(32.17, 55.27, 327.61).should eq({123, 40, 123})
    LCH.lch2rgb(0, 0, 0).should eq({0, 0, 0})
    LCH.lch2rgb(100, 0, 0).should eq({255, 255, 255})
    LCH.lch2rgb(47.65, 120.83, 326.41).should eq({198, 0, 207}) # fallback
  end

  it "clamps when converting lch to rgb" do
    LCH.lch2rgb(-1000, -1000, -1000).should eq({0, 0, 0})
    LCH.lch2rgb(1000, 1000, 1000).should eq({255, 255, 255})
  end

  it "accepts indexable in rgb2lch, lch2rgb" do
    LCH.rgb2lch([255, 255, 255]).should eq({100, 0, 0})
    LCH.rgb2lch({255, 255, 255}).should eq({100, 0, 0})
    LCH.lch2rgb([100, 0, 0]).should eq({255, 255, 255})
    LCH.lch2rgb({100, 0, 0}).should eq({255, 255, 255})
  end
end
