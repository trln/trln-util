require 'rsolr'
require 'trln/util/loggable'

module TRLN::Util

    # Wrapper around Rsolr to make some mass ingest operations easier.
    class SolrClient
        include TRLN::Util::Loggable

        attr_accessor :url, :collection, :client
        
        # Create a new connection to a Solr collection.
        # if passed a block, this object will be the  block's parameter, so you can implement
        # whatever logic you might need.
        # Logging: by default this class logs messages to  the standard error with `INFO` level.
        # You can customize this with the `quiet` or `verbose` options, which set the level to
        # `ERROR` and `DEBUG` respectively.  If this is not flexible enough for you, you can
        # pass in your own logger as an option.
        # @param [String] base_url the base URL of the Solr server
        # @param [String] collection the name of the collection we are updating to
        # @option options @see TRLN::Util::Loggable
        def initialize(base_url, collection,options={})
            @collection= collection
            
            base_url += '/' unless base_url.end_with?('/')
            @url = URI.join(base_url, @collection).to_s

            @logger = get_logger(options)          
            @logger.debug "Solr updates going to #{@url}"
            @client = RSolr.connect(:url => @url)
            
            if block_given?
                yield self
            end
        end

        # Send an array of (concatenated) JSON files containing indexable documents
        # to the update URL for the collection.
        # @param files [Array<String>] filenames containing JSON-encoded Solr documents.
        # @param commit_interval [Integer] number of files to submit before issuing a commit; set to 0 to commit after all files are processed,
        #    and to -1 to disable commiting entirely (manual commit).
        def json_doc_update(files,commit_interval =1) 
            count = 0
            if commit_interval == -1
                @logger.info "Auto commit disabled -- you're on your own"
            else
                @logger.debug "Will commit every #{commit_interval} file(s)"
            end
            files.each do |filename|
                @logger.debug "Processing #{filename}"
                begin
                    result = @client.update(:path => 'update/json/docs', :headers => { 'Content-Type' => 'application/json' }, :data => readit(filename))
                    @logger.debug "Response from solr to update: #{result}"
                rescue StandardError => e
                    @logger.error e
                end
                @logger.debug "Completed #{filename}"
                count += 1
                if commit_interval >= 0 and (count % commit_interval) ==0
                    @logger.debug "Solr commit"
                    @client.commit
                end
            end
            if commit_interval != -1
                @logger.info "Final commit"
                @client.commit
            end
            @logger.info "Solr update complete."
        end

        private

        # wrapper to allow us to read from files or filenames
        def readit(thing)
            if thing.respond_to?(:read)
                return thing.read
            else
                return File.open(thing).read
            end
        end

    end # SolrClient
end # module
