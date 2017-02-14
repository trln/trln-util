require 'spec_helper'
require 'trln/util/solr_join'

require 'json'

include TRLN::Util::Solr

include TestUtil

# minimalist mock of an RSolr client
class MockClient

  attr_reader :docs, :requests

  def initialize
    @data = JSON.parse(load_data("data/solr_results.json"))
    @requests = 0
  end

  def get(url,options={})
    @requests += 1
    params = options[:params]
    start = params[:start] || 0
    row_count = params.key?(:rows) ? params[:rows] : 10
    docs = @data['response']['docs'][start .. start+row_count-1] || []
    # copy the header, rewrite response.docs
    r= Marshal.load(Marshal.dump(@data))
    r['response']['docs'] = docs
    r
  end

  def post(url,options=())
    get(url,options)
  end
end



# build sample set of docs; all but one should 'join' against sample solr response (470140593)
def build_docs 
    isbns = %w[0470741791 9780470741252 0470751576 9780470744987 0470740787 0470743387 0470140593 0470743085 0470742534 0470745223 0470741287 0470736429 9780470743638 0470745355 9780470742259]
    docs = isbns.each_with_index.map { |isbn,idx|  [ "document-#{idx+1}", { 'isbn' => [ isbn ] } ] }.to_h
 end


describe TRLN::Util::Solr::JoinStrategy do

  
  it "inverts a hash correctly" do
      docs = build_docs        
      expected = docs.each.map { |docid,v| [ v['isbn'][0], [ docid ] ] }.to_h
      instance = JoinStrategy.new(docs,'isbn')
      expect(instance.invert!).to eq(expected)
  end

  
end

describe TRLN::Util::Solr::JoinClient  do

  it "loads test data correctly (failure here will cascade!)" do    
    data = load_data('data/solr_results.json') { |d|
      JSON.parse(d) 
    }
    expect(data).to_not be_nil
  end

  it "makes expected number of requests" do
    client = MockClient.new
    batch_size = 2
    docs = build_docs
    strat= JoinStrategy.new(docs, 'isbn')
    joinclient = JoinClient.new(client,strat, batch_size)
    expected_matches = docs.length - 1 # all but one should match; see build_docs note
    quot, remainder  = expected_matches.divmod(batch_size)
    expected_requests = quot + ( remainder > 0 ? 1 : 0 )
    joinclient.docs
    expect(client.requests).to eq(expected_requests)
  end

  it "joins results properly" do
    docs = build_docs
    client = MockClient.new
    strat = JoinStrategy.new(docs, 'isbn')
    joinclient = JoinClient.new(client,strat)
    joinclient.docs.each do |docid, doc|
      expect(doc['solr']).to_not be(nil) unless doc['isbn'].include?('0470140593')
    end
  end

end

