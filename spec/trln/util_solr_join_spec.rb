require 'spec_helper'
require 'trln/util/solr_join'

describe TRLN::Util::SolrJoinStrategy do
  include TRLN::Util

    def build_docs 
      isbns = %w[0470741791 9780470741252 0470751576 9780470744987 0470740787 0470743387 0470140593 0470743085 0470742534 0470745223 0470741287 0470736429 9780470743638 0470745355 9780470742259]
      docs = isbns.each_with_index.map do |isbn,idx|
        [ "document-#{idx+1}", { 'isbn' => [ isbn ] } ]
      end
      docs.to_h
    end

    it "inverts a hash correctly" do
        docs = build_docs
        expected = docs.each.map do |docid,isbns|
          [ isbns[0], [ docid ]
        end.to_h
        instance = SolrJoinStrategy.new('isbn')
        expect(instance.invert!).to eq(qxpected)
    end

end
