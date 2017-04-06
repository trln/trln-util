# container for a refinement that adds a useful
# method to the Hash class
module MyHashUtil

    refine Hash do

        def invert_value(k,v,out)
            out[v] ||= []
            out[v] << k
        end

        # Returns a new Hash using the values of this Hash as keys, and
        # the keys of this Hash as values.  To provide uniform support
        # for cases where values are non-unique, the values in the returned
        # hash will always be an Array of the corresponding keys (e.g. 
        # +{ a => b, c => b, d => e }.safe_invert+ produces 
        # +{ b => [a,c], d => [e] }+
        # Can optionally be passed a block to compute a new hash key
        # from a complex object.
        # @yield [Object] a block that returns the new hash key for
        #  each value in the original hash
        def safe_invert
            each_with_object({}) do |(key,value),out|
                if block_given?
                    val = yield value
                else
                    val = value
                end
                val = [val] unless val.respond_to?(:each)
                val.each { |v|
                    invert_value(key,v,out)
                }
            end
        end
    end # refinement
end # module


# Utilities for enriching documents with 
module TRLN::Util::Solr
    using MyHashUtil

    # Extensible collection of methods for formulating queries
    # against an array of documents against a Solr index and
    # matching results to input documents.  Default implementation
    # covers case where a single field from the input document is queried 
    # and maps 1:1 or m:n onto a single field in solr.
    class JoinStrategy

        attr_reader :key, :index_name, :query

        attr_accessor :docs

        # Constructor for simple cases
        # @param docs [Array<Hash>] input documents to be queried against.
        # @param key [String] the field in input documents to match against
        # @param index_field [String] the field in the index against 
        #   which input documents should be matched
        #
        # If +key+ is provided and +index_field+ is not,  +key+ 
        # will be interpreted both as the field name and the index name.
        def initialize(docs, key=nil,index_field=nil)
        @docs = docs
            @key = key
            @index_field = index_field
            @index_field ||= @key
        end

        # Inverts the +docs+ map to enable matching results from Solr to the
        # input documents.  This mapping is used by the default joining algorithm to
        # match results  from Solr against input documents by ID, but may not be needed
        # for more complex cases.
        # @yield [Object] optional block used to compute the inverse key based
        #  on the value
        #  @see #join!
        def invert!
            if block_given?
                @inverse = @docs.safe_invert { |v| yield v }
            else
               @inverse = @docs.safe_invert { |v| @key.nil? ? v : v[@key] }
            end
            @inverse
        end

        def query
            @query ||= build_query
        end

        # Builds the actual query.  Default is to return
        # +[index_name]: ( doc1.key OR doc2.key OR ...)+
        # @yield Array<Hash,Object] a block that will be used
        #  to construct the query.
        #  @yield [Array<Objects>] optional block that builds a query from the input
        #  documents.
        def build_query
            if block_given?
                yield @docs 
            else
                vals = @docs.map { |k,v| v[@key] }.flatten.uniq
                "#{@index_field}: (#{vals.join(' OR ')} )"
            end
        end

        # Builds the join query and stores the value.
        # @yield [Array<Hash>] optional block that builds input documents used to build the query
        def build_query!
            if block_given?
                @query = build_query { |x| yield x }
            else
                @query = build_query
            end
        end

        # Implements a default join strategy: extracts +:index_field+
        # from each document in the solr results and tries to find
        # matches against input documents with matching +:key+s,
        # altering them in place.  Modifies the +docs+  parameter
        # in-place.
        # @param result [Hash] a Solr response
        def join!(result)
            @inverse ||= invert!
            response_docs = result['response']['docs']
            response_docs.each do |rd|
                doc_ids = rd[@index_field].map{|x| @inverse[x]}.reject(&:nil?)
                    .flatten
                doc_ids.each do |docid|
                    @docs[docid]['solr'] = rd if @docs.key?(docid)
                end
            end 
        end
    end

    # Executes a JoinStrategy against a Solr index, as
    # represented by an already-configured RSolr client
     
    class JoinClient

        attr_reader :strategy, :expected, :rows

        # Creates a new joiner against the documents stored
        # in Solr.
        # @param client [RSolr::Client] the client used to make the query
        # @param strategy [SolrJoinStrategy] the join strategy to be used
        #  ones that appear in the +id+ field in Solr), and the values
        #  are the input documents themselves.
        #  @param rows_per_request [Fixnum] the maximum number of rows
        #   to fetch in each request.
        def initialize(client,strategy,rows_per_request=50)
            @client = client
            @strategy = strategy
            @expected = -1
            @rows = rows_per_request
        end

        def query
            @query ||= build_query
        end

        # Gets the enriched (joined) documents by executing the query
        # against the Solr index.
        def docs
            run_query unless @expected >= 0
            @strategy.docs
        end

        def execute(start=0)
            max_rows = @rows || @strategy.docs.length 
            params =  { :q => query, :rows => max_rows, :start => start }
            
            if query.length < 2048
                result = @client.get('select', :params => params)
            else
                result = @client.post('select', :params => params)
            end

            return result['response']['docs'].empty? ? false : result
        end

        def build_query
            if block_given?
                @query = @strategy.build_query { yield }
            else
                @query = @strategy.build_query
            end
        end

        def run_query 
            start = 0
            while result = execute(start) 
                @expected = result['response']['numFound']
                count = result['response']['docs'].length
                start += count
                if block_given?
                    yield result
                else
                    @strategy.join!(result)
                end
                break if start >= @expected
            end
        end
    end
end
