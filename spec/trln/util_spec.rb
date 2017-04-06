require 'spec_helper'

describe TRLN::Util do
  it 'has a version number' do
    expect(TRLN::Util::VERSION).not_to be nil
  end

  it 'does not find resources that do not exist' do
    things = TRLN::Util.find_resources('this', 'that', 'the_other')
    expect(things.length).to eq (3)
    expect(things.select {|f| File.exist?(f) }.length).to eq(0)
  end

  it 'finds resources that do exist' do
    files = TRLN::Util.find_resources("something.fake.gz")
    expect(files.length).to eq(1)
    expect(File.exist?(files[0])).to be(true)
  end

  it "correctly reads gzip files" do
    the_file = File.expand_path("../../data/something.fake.gz", __FILE__)
    expect(File.exist?(the_file)).to be
    result = TRLN::Util.get_readable(the_file)
    expect(result).to be_a(Zlib::GzipReader)
 end




end
