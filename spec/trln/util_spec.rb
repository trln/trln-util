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

end
