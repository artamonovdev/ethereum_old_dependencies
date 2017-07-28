require 'spec_helper'

describe Ethereum::Encoder do

  let (:encoder) { Ethereum::Encoder.new }
  let (:decoder) { Ethereum::Decoder.new }
  let(:function) { Ethereum::Function.new(abi) }

  it "parse type" do
    expect(Ethereum::Abi::parse_type("bool")).to eq ["bool", nil]
    expect(Ethereum::Abi::parse_type("uint32")).to eq ["uint", "32"]
    expect(Ethereum::Abi::parse_type("bytes32")).to eq ["bytes", "32"]
    expect(Ethereum::Abi::parse_type("fixed128x128")).to eq ["fixed", "128x128"]
  end

  RSpec::Matchers.define :encode_and_decode do |actual|
    match do |type|
      (encoder.encode(type, actual) == @expected) && (decoder.decode(type, @expected) == actual)
    end
    chain(:to) { |expected| @expected = expected }
  end

  context "uint" do
    specify { expect("uint").to encode_and_decode(20).to("0000000000000000000000000000000000000000000000000000000000000014") }
    specify { expect("uint32").to encode_and_decode(5).to("0000000000000000000000000000000000000000000000000000000000000005") }
    specify { expect("uint4").to encode_and_decode(5).to("0000000000000000000000000000000000000000000000000000000000000005") }
    specify { expect("uint256").to encode_and_decode(5).to("0000000000000000000000000000000000000000000000000000000000000005") }
    it { expect(decoder.decode("uint8", "00000000000000000000000000000000000000000000000000000000000003330000000000000000000000000000000000000000000000000000000000000110", 64)).to eq 16 }
  end

  context "int" do
    specify { expect("int").to encode_and_decode(20).to("0000000000000000000000000000000000000000000000000000000000000014") }
    specify { expect("int32").to encode_and_decode(5).to("0000000000000000000000000000000000000000000000000000000000000005") }
    specify { expect("int8").to encode_and_decode(5).to("0000000000000000000000000000000000000000000000000000000000000005") }
    specify { expect("int256").to encode_and_decode(5).to("0000000000000000000000000000000000000000000000000000000000000005") }
    specify { expect("int256").to encode_and_decode(-20).to("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffec") }
    specify { expect("int32").to encode_and_decode(-1).to("ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff") }
    it { expect(decoder.decode("int8", "00000000000000000000000000000000000000000000000000000000000003330000000000000000000000000000000000000000000000000000000000000110", 64)).to eq 16 }
  end

  context "bool" do
    specify { expect("bool").to encode_and_decode(true).to("0000000000000000000000000000000000000000000000000000000000000001") }
    specify { expect("bool").to encode_and_decode(false).to("0000000000000000000000000000000000000000000000000000000000000000") }
  end

  context "address" do
    specify { expect("address").to encode_and_decode("0000000000000000000000000000000000000000").to("0000000000000000000000000000000000000000000000000000000000000000") }
    it { expect { decoder.decode("address", "000000000000000000000000000000000000000") }.to raise_error ArgumentError }
    it { expect { encoder.encode("address", "000000000000000000000000000000000000000") }.to raise_error ArgumentError }
    it { expect(encoder.encode("address", "0x0000000000000000000000000000000000000000")).to eq "0000000000000000000000000000000000000000000000000000000000000000" }
    it { expect(decoder.decode("address", "0x0000000000000000000000000000000000000000000000000000000000000000")).to eq "0000000000000000000000000000000000000000" }
    it { expect(decoder.decode("address", "10000000000000000000000000000000000000000000000000000000000000012000000000000000000000000000000000000000000000000000000000000002", 64)).to eq "0000000000000000000000000000000000000002" }
  end

  context "bytes32" do
    let (:expected) { '6461766500000000000000000000000000000000000000000000000000000000' }
    specify { expect("bytes32").to encode_and_decode("dave").to(expected) }
  end

  context "fixed" do
    specify { expect("fixed").to encode_and_decode(2.125).to("0000000000000000000000000000000220000000000000000000000000000000") }
    specify { expect("fixed").to encode_and_decode(8.5).to("0000000000000000000000000000000880000000000000000000000000000000") }
    it { expect(encoder.encode("fixed128x128", 8.5)).to eq "0000000000000000000000000000000880000000000000000000000000000000" }
    it { expect(encoder.encode("fixed252x4", 8.5)).to eq "0000000000000000000000000000000000000000000000000000000000000088" }
    it { expect(decoder.decode("fixed4x4", "0000000000000000000000000000000000000000000000000000000000008888")).to eq 8.5 }
    it { expect(decoder.decode("fixed4x4", "X0000000000000000000000000000000000000000000000000000000000008888", 1)).to eq 8.5 }
  end

  context "bytes" do
    let (:location) { '0000000000000000000000000000000000000000000000000000000000000020' }
    let (:size) { '0000000000000000000000000000000000000000000000000000000000000004' }
    let (:content) { '6461766500000000000000000000000000000000000000000000000000000000' }
    let (:expected) { location + size + content }
    it { expect(encoder.encode("bytes", "dave").join).to eq expected }
    it { expect(decoder.decode("bytes", expected)).to eq "dave" }
  end

  context "string" do
    let (:hex1) { "000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000046461766500000000000000000000000000000000000000000000000000000000" }
    let (:hex2) { "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000c6d69c5826f62c499647a6b610000000000000000000000000000000000000000" }
    it { expect(encoder.encode("string", "dave").join).to eq hex1 }
    it { expect(decoder.decode("string", hex1)).to eq "dave" }
    it { expect(encoder.encode("string", "miłobędzka").join).to eq hex2 }
    it { expect(decoder.decode("string", hex2)).to eq "miłobędzka" }
  end

  context "long string" do
    let (:message) { "a" * 1000 }
    it { expect(decoder.decode("string", encoder.encode("string", message).join(""))).to eq message }
  end

  context "decode function outputs" do
    let(:abi) { {"outputs" => [{"type" => "int"}, {"type" => "string", "name" => ""}], "inputs" => [] } }
    let (:data) { "0x00000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000c6d69c5826f62c499647a6b610000000000000000000000000000000000000000" }
    it { expect(decoder.decode_arguments(function.outputs, data)).to eq [20, "miłobędzka"] }
  end

  context "encode simple function input" do
    let(:abi) { {"inputs" => [{"type" => "uint32"}, {"type" => "bool", "name" => ""}], "outputs" => [] } }
    let (:data) { "00000000000000000000000000000000000000000000000000000000000000450000000000000000000000000000000000000000000000000000000000000001" }
    it { expect(encoder.encode_arguments(function.inputs, [69, true])).to eq data }
  end

  context "encode bytes function input" do
    let(:abi) { {"inputs" => [{"type" => "bytes"}, {"type" => "bool", "name" => ""}], "outputs" => [] } }
    let (:data) { "0000000000000000000000000000000000000000000000000000000000000040" + "0000000000000000000000000000000000000000000000000000000000000001" + "0000000000000000000000000000000000000000000000000000000000000004" + "6461766500000000000000000000000000000000000000000000000000000000"}
    it { expect(encoder.encode_arguments(function.inputs, ["dave", true])).to eq data }
  end

  context "encode and decode string argument" do
    let(:abi) { {"inputs" => [{"type" => "string"}], "outputs" => [] } }
    let (:data) { "00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000008c5bcc3b3c582c487000000000000000000000000000000000000000000000000" }
    it { expect(encoder.encode_arguments(function.inputs, ["żółć"])).to eq data }
    it { expect(decoder.decode_arguments(function.inputs, data)).to eq ["żółć"] }
  end

  context "encode and decode 2 string arguments" do
    let(:abi) { {"inputs" => [{"type" => "string"}, {"type" => "string"}], "outputs" => [] } }
    let (:data) { "000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000008c5bcc3b3c582c4870000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008c5bcc3b3c582c487000000000000000000000000000000000000000000000000" }
    it { expect( encoder.encode_arguments(function.inputs, ["żółć", "żółć"])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq ["żółć", "żółć"] }
  end

  context "encode static array of ints" do
    let(:abi) { {"inputs" => [{"type" => "int[2]"}], "outputs" => [] } }
    let (:data) { "00000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000014" }
    it { expect( encoder.encode_arguments(function.inputs, [[5, 20]])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq [[5, 20]] }
  end

  context "encode static array of ints with int before in arg list" do
    let(:abi) { {"inputs" => [{"type" => "int"}, {"type" => "int[2]"}], "outputs" => [] } }
    let (:data) { "000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000014" }
    it { expect( encoder.encode_arguments(function.inputs, [2, [5, 20]])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq [2, [5, 20]] }
  end

  context "encode string and static array of ints" do
    let(:abi) { {"inputs" => [{"type" => "string"}, {"type" => "int[2]"}], "outputs" => [] } }
    let (:data) { "0000000000000000000000000000000000000000000000000000000000000060000000000000000000000000000000000000000000000000000000000000000500000000000000000000000000000000000000000000000000000000000000140000000000000000000000000000000000000000000000000000000000000008c5bcc3b3c582c487000000000000000000000000000000000000000000000000" }
    it { expect( encoder.encode_arguments(function.inputs, ["żółć", [5, 20]])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq ["żółć", [5, 20]] }
  end

  context "encode two int arrays" do
    let(:abi) { {"inputs" => [{"type" => "int[]"}, {"type" => "int[]"}], "outputs" => [] } }
    let (:data) { "000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000003" }
    it { expect( encoder.encode_arguments(function.inputs, [[7, 3], [7, 3]])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq [[7, 3], [7, 3]] }
  end

  context "encode two byte32 arrays" do
    let(:abi) { {"inputs" => [{"type" => "bytes32[]"}, {"type" => "bytes32[]"}], "outputs" => [] } }
    let (:data) { "000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000a0000000000000000000000000000000000000000000000000000000000000000261000000000000000000000000000000000000000000000000000000000000006200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000261000000000000000000000000000000000000000000000000000000000000006200000000000000000000000000000000000000000000000000000000000000" }
    it { expect( encoder.encode_arguments(function.inputs, [["a", "b"], ["a", "b"]])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq [["a", "b"], ["a", "b"]] }
  end

  context "encode two byte32 arrays and 2 ints" do
    let(:abi) { {"inputs" => [{"type" => "bytes32[]"}, {"type" => "bytes32[]"}, {"type" => "int[]"}, {"type" => "int[]"}], "outputs" => [] } }
    let (:data) { "000000000000000000000000000000000000000000000000000000000000008000000000000000000000000000000000000000000000000000000000000000e0000000000000000000000000000000000000000000000000000000000000014000000000000000000000000000000000000000000000000000000000000001a0000000000000000000000000000000000000000000000000000000000000000261000000000000000000000000000000000000000000000000000000000000006200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000261000000000000000000000000000000000000000000000000000000000000006200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000003000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000070000000000000000000000000000000000000000000000000000000000000003" }
    it { expect( encoder.encode_arguments(function.inputs, [["a", "b"], ["a", "b"], [7,3], [7,3]])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq [["a", "b"], ["a", "b"], [7,3], [7,3]] }
  end

  context "encode simple dynamic array" do
    let (:abi) { {"inputs" => [{"type" => "int[]"}], "outputs" => [] } }
    let (:data) { "0000000000000000000000000000000000000000000000000000000000000020000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000014" }
    it { expect( encoder.encode_arguments(function.inputs, [[5, 20]])).to eq data }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq [[5, 20]] }
  end

  context "encode dynamic array with extra string" do
    let (:abi) { {"inputs" => [{"type" => "string"}, {"type" => "int[]"}], "outputs" => [] } }
    let (:data) { "000000000000000000000000000000000000000000000000000000000000004000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000008c5bcc3b3c582c487000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000050000000000000000000000000000000000000000000000000000000000000014" }
    it { expect( decoder.decode_arguments(function.inputs, data)).to eq ["żółć", [5, 20]] }
    it { expect( encoder.encode_arguments(function.inputs, ["żółć", [5, 20]])).to eq data }
  end

  context "raise exception if too many args" do
    let(:abi) { {"inputs" => [{"type" => "string"}], "outputs" => [] } }
    let (:data) { "00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000008c5bcc3b3c582c487000000000000000000000000000000000000000000000000" }
    it { expect { encoder.encode_arguments(function.inputs, ["żółć", 2]) }.to raise_error "Wrong number of arguments" }
  end

  context "raise exception if not enough args" do
    let(:abi) { {"inputs" => [{"type" => "string"}, {"type" => "bool"}], "outputs" => [] } }
    let (:data) { "00000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000008c5bcc3b3c582c487000000000000000000000000000000000000000000000000" }
    it { expect { encoder.encode_arguments(function.inputs, ["żółć"]) }.to raise_error "Wrong number of arguments" }
  end

end