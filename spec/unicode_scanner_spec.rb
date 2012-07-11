# encoding: utf-8

require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

describe UnicodeScanner do
  it "should pass all the class-level examples" do
    s = UnicodeScanner.new('This is an example string')
    s.eos?.should == false

    s.scan(/\w+/).should == "This"
    s.scan(/\w+/).should == nil
    s.scan(/\s+/).should == " "
    s.scan(/\s+/).should == nil
    s.scan(/\w+/).should == "is"
    s.eos?.should == false

    s.scan(/\s+/).should == " "
    s.scan(/\w+/).should == "an"
    s.scan(/\s+/).should == " "
    s.scan(/\w+/).should == "example"
    s.scan(/\s+/).should == " "
    s.scan(/\w+/).should == "string"
    s.eos?.should == true

    s.scan(/\s+/).should == nil
    s.scan(/\w+/).should == nil
  end

  it "should pass the #concat example" do
    s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
    s.scan(/Fri /)
    s << " +1000 GMT"
    s.string.should == "Fri Dec 12 1975 14:39 +1000 GMT"
    s.scan(/Dec/).should == "Dec"
  end

  it "should pass the #[] example" do
    s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
    s.scan(/(\w+) (\w+) (\d+) /).should == "Fri Dec 12 "
    s[0].should == "Fri Dec 12 "
    s[1].should == "Fri"
    s[2].should == "Dec"
    s[3].should == "12"
    s.post_match.should == "1975 14:39"
    s.pre_match.should == ""
  end

  it "should pass the #beginning_of_line? example" do
    s = UnicodeScanner.new("test\ntest\n")
    s.bol?.should == true
    s.scan(/te/)
    s.bol?.should == false
    s.scan(/st\n/)
    s.bol?.should == true
    s.terminate
    s.bol?.should == true
  end

  it "should pass the #check example" do
    s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
    s.check(/Fri/).should == "Fri"
    s.pos.should == 0
    s.matched.should == "Fri"
    s.check(/12/).should == nil
    s.matched.should == nil
  end

  it "should pass the #check_until example" do
    s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
    s.check_until(/12/).should == "Fri Dec 12"
    s.pos.should == 0
    s.matched.should == "12"
  end

  it "should pass the #eos? example" do
    s = UnicodeScanner.new('test string')
    s.eos?.should == false
    s.scan(/test/)
    s.eos?.should == false
    s.terminate
    s.eos?.should == true
  end

  it "should pass the #exist? example" do
    s = UnicodeScanner.new('test string')
    s.exist?(/s/).should == 3
    s.scan(/test/).should == "test"
    s.exist?(/s/).should == 2
    s.exist?(/e/).should == nil
  end

  it "should pass a tweaked version of the #getch example" do
    s = UnicodeScanner.new("ab")
    s.getch.should == "a"
    s.getch.should == "b"
    s.getch.should == nil

    s = UnicodeScanner.new("ぁ")
    s.getch.should == "ぁ" # Japanese hira-kana "A" in EUC-JP
    s.getch.should == nil
  end

  it "should pass the #inspect example" do
    s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
    s.inspect.should == '#<UnicodeScanner 0/21 @ "Fri D...">'
    s.scan_until(/12/).should == "Fri Dec 12"
    s.inspect.should == '#<UnicodeScanner 10/21 "...ec 12" @ " 1975...">'
  end

  it "should pass the #match? example" do
    s = UnicodeScanner.new('test string')
    s.match?(/\w+/).should == 4
    s.match?(/\w+/).should == 4
    s.match?(/\s+/).should == nil
  end

  it "should pass the #matched example" do
    s = UnicodeScanner.new('test string')
    s.match?(/\w+/).should == 4
    s.matched.should == "test"
  end

  it "should pass the #matched? example" do
    s = UnicodeScanner.new('test string')
    s.match?(/\w+/).should == 4
    s.matched?.should == true
    s.match?(/\d+/).should == nil
    s.matched?.should == false
  end

  it "should pass the #matched_size example" do
    s = UnicodeScanner.new('test string')
    s.check(/\w+/).should == "test"
    s.matched_size.should == 4
    s.check(/\d+/).should == nil
    s.matched_size.should == nil
  end

  it "should pass the #peek example" do
    s = UnicodeScanner.new('test string')
    s.peek(7).should == "test st"
    s.peek(7).should == "test st"
  end

  it "should pass the #pos example" do
    s = UnicodeScanner.new('test string')
    s.pos.should == 0
    s.scan_until(/str/).should == "test str"
    s.pos.should == 8
    s.terminate.inspect.should == "#<UnicodeScanner fin>"
    s.pos.should == 11
  end

  it "should pass the #pos= example" do
    s = UnicodeScanner.new('test string')
    (s.pos = 7).should == 7
    s.rest.should == "ring"
  end

  it "should pass the #post_match/#pre_match example" do
    s = UnicodeScanner.new('test string')
    s.scan(/\w+/).should == "test"
    s.scan(/\s+/).should == " "
    s.pre_match.should == "test"
    s.post_match.should == "string"
  end

  it "should pass the #scan example" do
    s = UnicodeScanner.new('test string')
    s.scan(/\w+/).should == "test"
    s.scan(/\w+/).should == nil
    s.scan(/\s+/).should == " "
    s.scan(/\w+/).should == "string"
    s.scan(/./).should == nil
  end

  it "should pass the #scan_until example" do
    s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
    s.scan_until(/1/).should == "Fri Dec 1"
    s.pre_match.should == "Fri Dec "
    s.scan_until(/XYZ/).should == nil
  end

  it "should pass the #skip example" do
    s = UnicodeScanner.new('test string')
    s.skip(/\w+/).should == 4
    s.skip(/\w+/).should == nil
    s.skip(/\s+/).should == 1
    s.skip(/\w+/).should == 6
    s.skip(/./).should == nil
  end

  it "should pass the half-finished #skip_until example" do
    s = UnicodeScanner.new("Fri Dec 12 1975 14:39")
    s.skip_until(/12/).should == 10
  end

  it "should pass the #unscan example" do
    s = UnicodeScanner.new('test string')
    s.scan(/\w+/).should == "test"
    s.unscan
    s.scan(/../).should == "te"
    s.scan(/\d/).should == nil
    -> { s.unscan }.should raise_error(ScanError, 'unscan failed: previous match record not exist')
  end
end
