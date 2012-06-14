require 'rspec'
require 'ostruct'
require 'extensions'

describe "Extensions" do
  describe "Enumerable#mash" do
    it { [[:a, 1], [:b, 2]].mash.should == {:a => 1, :b => 2} }
    it { [[:a, 1], nil, [:b, 2]].mash.should == {:a => 1, :b => 2} }
    it { [[:a, 1], [:b, 2]].mash { |k, v| [k.to_s, 2*v] }.should == {"a" => 2, "b" => 4} }
  end
  
  describe "Enumerable#map_select" do
    it { [1, 2, 3].map_select { |x| 2*x if x > 1 }.should == [4, 6] }
  end

  describe "Enumerable#map_detect" do
    it { [1, 2, 3].map_detect { |x| 2*x if x > 1 }.should == 4 }
    it { [1, 2, 3].map_detect { |x| 2*x if x > 10 }.should == nil }
  end
  
  describe "String#split_at" do
    it { "12345678".split_at(0).should == ["", "12345678"] }
    it { "12345678".split_at(3).should == ["123", "45678"] }
    it { "12345678".split_at(10).should == ["12345678", ""] }
  end

  FalsyValues = [nil, false, "", "  \t \n", [], {}]
  TruishValues = [true, "a", [1], {:a => 1}, OpenStruct.new]
  
  describe "#present?" do
    FalsyValues.each { |v| v.present?.should == false }
    TruishValues.each { |v| v.present?.should == true }
  end

  describe "#blank?" do
    FalsyValues.each { |v| v.blank?.should == true }
    TruishValues.each { |v| v.blank?.should == false }
  end

  describe "#blank?" do
    FalsyValues.each { |v| v.presence.should == nil }
    TruishValues.each { |v| v.presence.should == v }
  end
  
  describe "Object#to_bool" do
    it { nil.to_bool.should == false }
    it { false.to_bool.should == false }
    it { true.to_bool.should == true }
    it { "".to_bool.should == true }
    it { [].to_bool.should == true }
    it { {}.to_bool.should == true }
  end
  
  describe "Object#whitelist" do
    it { 1.whitelist(1, 2, 3).should == 1 }
    it { 1.whitelist(2, 1, 3).should == 1 }
    it { 1.whitelist(2, 3).should == nil }
  end

  describe "Object#blacklist" do
    it { 1.blacklist(1, 2, 3).should == nil }
    it { 1.blacklist(2, 1, 3).should == nil}
    it { 1.blacklist(2, 3).should == 1 }
  end
  
  describe "Object#send_if_responds" do
    it { "123".send_if_responds(:to_i).should == 123 }
    it { "123".send_if_responds(:non_existing_method).should == nil }
  end
  
  describe "Object#in?" do
    it { 1.in?([1, 2, 3]).should == true }
    it { 4.in?([1, 2, 3]).should == false } 
  end

  describe "Object#not_in?" do
    it { 1.not_in?([1, 2, 3]).should == false }
    it { 4.not_in?([1, 2, 3]).should == true } 
  end
  
  describe "Object#maybe" do
    it { 123.maybe.to_s.should == "123" }
    it { nil.maybe.to_s.should == nil }
    it { 123.maybe { |x| x.to_s }.should == "123" }
    it { nil.maybe { |x| x.to_s }.should == nil }
  end
  
  describe "Kernel#state_loop" do
    circular_accumulator(1) do |x|
      x + 1 if x < 5    
    end.to_a.should == [1, 2, 3, 4, 5]
  end
  
  describe "OpenStruct.new_recursive" do
    it { OpenStruct.new_recursive(:a => 1).should == OpenStruct.new(:a => 1) }
    it { OpenStruct.new_recursive(:a => 1, :b => {:c => 3}).should == 
           OpenStruct.new(:a => 1, :b => OpenStruct.new(:c => 3)) }
  end
  
  describe "File.write" do
    let(:filename) { ".extensions_spec.rb.test" }
    after { File.delete(filename) if File.exists?(filename) }
    
    it "writes data to file" do
      File.write(filename, "hello")
      File.read(filename).should == "hello"
    end
  end
end
