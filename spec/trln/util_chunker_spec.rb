require 'spec_helper'

describe TRLN::Util::Chunker do

    it 'chunker chunks files appropriately' do
        b_size = 3
        recs = %w[this that the_other thing dis dat dese dose]
        chunker = TRLN::Util::Chunker.new(batch_size: b_size)
        recs.each { |r| chunker.write(r) }
        dm = recs.length.divmod(b_size)
        el = dm[0] + dm[1] > 0 ? 1 : 0
        expect(chunker.files.length).to eq(el)
    end

    it 'chunker cleans up after itself' do
      chunker = TRLN::Util::Chunker.new()
      chunker.write('some data')
      files = chunker.files.select { |f| File.exist?(f) }
      expect(files.length).to eq(1)
      chunker.cleanup
      expect( files.select { |f| File.exist?(f) }.length).to eq(0)
      expect(File.directory?(chunker.dir)).to eq(false)
    end

end