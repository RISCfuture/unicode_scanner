# frozen_string_literal: true

require File.expand_path("#{File.dirname(__FILE__)}/spec_helper")

RSpec.describe UnicodeScanner do
  it "passes all the class-level examples" do
    s = described_class.new("This is an example string")
    expect(s.eos?).to be(false)

    expect(s.scan(/\w+/)).to eq("This")
    expect(s.scan(/\w+/)).to be_nil
    expect(s.scan(/\s+/)).to eq(" ")
    expect(s.scan(/\s+/)).to be_nil
    expect(s.scan(/\w+/)).to eq("is")
    expect(s.eos?).to be(false)

    expect(s.scan(/\s+/)).to eq(" ")
    expect(s.scan(/\w+/)).to eq("an")
    expect(s.scan(/\s+/)).to eq(" ")
    expect(s.scan(/\w+/)).to eq("example")
    expect(s.scan(/\s+/)).to eq(" ")
    expect(s.scan(/\w+/)).to eq("string")
    expect(s.eos?).to be(true)

    expect(s.scan(/\s+/)).to be_nil
    expect(s.scan(/\w+/)).to be_nil
  end

  it "passes the #concat example" do
    s = described_class.new(+"Fri Dec 12 1975 14:39")
    s.scan(/Fri /)
    s << " +1000 GMT"
    expect(s.string).to eq("Fri Dec 12 1975 14:39 +1000 GMT")
    expect(s.scan(/Dec/)).to eq("Dec")
  end

  it "passes the #[] example" do
    s = described_class.new("Fri Dec 12 1975 14:39")
    expect(s.scan(/(\w+) (\w+) (\d+) /)).to eq("Fri Dec 12 ")
    expect(s[0]).to eq("Fri Dec 12 ")
    expect(s[1]).to eq("Fri")
    expect(s[2]).to eq("Dec")
    expect(s[3]).to eq("12")
    expect(s.post_match).to eq("1975 14:39")
    expect(s.pre_match).to eq("")
  end

  it "passes the #beginning_of_line? example" do
    s = described_class.new("test\ntest\n")
    expect(s.bol?).to be(true)
    s.scan(/te/)
    expect(s.bol?).to be(false)
    s.scan(/st\n/)
    expect(s.bol?).to be(true)
    s.terminate
    expect(s.bol?).to be(true)
  end

  it "passes the #check example" do
    s = described_class.new("Fri Dec 12 1975 14:39")
    expect(s.check(/Fri/)).to eq("Fri")
    expect(s.pos).to eq(0)
    expect(s.matched).to eq("Fri")
    expect(s.check(/12/)).to be_nil
    expect(s.matched).to be_nil
  end

  it "passes the #check_until example" do
    s = described_class.new("Fri Dec 12 1975 14:39")
    expect(s.check_until(/12/)).to eq("Fri Dec 12")
    expect(s.pos).to eq(0)
    expect(s.matched).to eq("12")
  end

  it "passes the #eos? example" do
    s = described_class.new("test string")
    expect(s.eos?).to be(false)
    s.scan(/test/)
    expect(s.eos?).to be(false)
    s.terminate
    expect(s.eos?).to be(true)
  end

  it "passes the #exist? example" do
    s = described_class.new("test string")
    expect(s.exist?(/s/)).to eq(3)
    expect(s.scan(/test/)).to eq("test")
    expect(s.exist?(/s/)).to eq(2)
    expect(s.exist?(/e/)).to be_nil
  end

  it "passes a tweaked version of the #getch example" do
    s = described_class.new("ab")
    expect(s.getch).to eq("a")
    expect(s.getch).to eq("b")
    expect(s.getch).to be_nil

    s = described_class.new("ぁ")
    expect(s.getch).to eq("ぁ") # Japanese hira-kana "A" in EUC-JP
    expect(s.getch).to be_nil
  end

  it "passes the #inspect example" do
    s = described_class.new("Fri Dec 12 1975 14:39")
    expect(s.inspect).to eq('#<UnicodeScanner 0/21 @ "Fri D...">')
    expect(s.scan_until(/12/)).to eq("Fri Dec 12")
    expect(s.inspect).to eq('#<UnicodeScanner 10/21 "...ec 12" @ " 1975...">')
  end

  it "passes the #match? example" do
    s = described_class.new("test string")
    expect(s.match?(/\w+/)).to eq(4)
    expect(s.match?(/\w+/)).to eq(4)
    expect(s.match?(/\s+/)).to be_nil
  end

  it "passes the #matched example" do
    s = described_class.new("test string")
    expect(s.match?(/\w+/)).to eq(4)
    expect(s.matched).to eq("test")
  end

  it "passes the #matched? example" do
    s = described_class.new("test string")
    expect(s.match?(/\w+/)).to eq(4)
    expect(s.matched?).to be(true)
    expect(s.match?(/\d+/)).to be_nil
    expect(s.matched?).to be(false)
  end

  it "passes the #matched_size example" do
    s = described_class.new("test string")
    expect(s.check(/\w+/)).to eq("test")
    expect(s.matched_size).to eq(4)
    expect(s.check(/\d+/)).to be_nil
    expect(s.matched_size).to be_nil
  end

  it "passes the #peek example" do
    s = described_class.new("test string")
    expect(s.peek(7)).to eq("test st")
    expect(s.peek(7)).to eq("test st")
  end

  it "passes the #pos example" do
    s = described_class.new("test string")
    expect(s.pos).to eq(0)
    expect(s.scan_until(/str/)).to eq("test str")
    expect(s.pos).to eq(8)
    expect(s.terminate.inspect).to eq("#<UnicodeScanner fin>")
    expect(s.pos).to eq(11)
  end

  it "passes the #pos= example" do
    s = described_class.new("test string")
    expect(s.pos = 7).to eq(7)
    expect(s.rest).to eq("ring")
  end

  it "passes the #post_match/#pre_match example" do
    s = described_class.new("test string")
    expect(s.scan(/\w+/)).to eq("test")
    expect(s.scan(/\s+/)).to eq(" ")
    expect(s.pre_match).to eq("test")
    expect(s.post_match).to eq("string")
  end

  it "passes the #scan example" do
    s = described_class.new("test string")
    expect(s.scan(/\w+/)).to eq("test")
    expect(s.scan(/\w+/)).to be_nil
    expect(s.scan(/\s+/)).to eq(" ")
    expect(s.scan(/\w+/)).to eq("string")
    expect(s.scan(/./)).to be_nil
  end

  it "passes the #scan_until example" do
    s = described_class.new("Fri Dec 12 1975 14:39")
    expect(s.scan_until(/1/)).to eq("Fri Dec 1")
    expect(s.pre_match).to eq("Fri Dec ")
    expect(s.scan_until(/XYZ/)).to be_nil
  end

  it "passes the #skip example" do
    s = described_class.new("test string")
    expect(s.skip(/\w+/)).to eq(4)
    expect(s.skip(/\w+/)).to be_nil
    expect(s.skip(/\s+/)).to eq(1)
    expect(s.skip(/\w+/)).to eq(6)
    expect(s.skip(/./)).to be_nil
  end

  it "passes the half-finished #skip_until example" do
    s = described_class.new("Fri Dec 12 1975 14:39")
    expect(s.skip_until(/12/)).to eq(10)
  end

  it "passes the #unscan example" do
    s = described_class.new("test string")
    expect(s.scan(/\w+/)).to eq("test")
    s.unscan
    expect(s.scan(/../)).to eq("te")
    expect(s.scan(/\d/)).to be_nil
    expect { s.unscan }.to raise_error(ScanError, "unscan failed: previous match record not exist")
  end
end
