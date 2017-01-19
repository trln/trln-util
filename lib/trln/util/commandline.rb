require 'trln/util/chunker'
require 'trln/util/ice_extractor'
require 'trln/util/xml'
require 'thor'
require 'fileutils'
require 'logger'

module TRLN::Util

    # Implementation of +trln+ command-line utility.  Public methods in this class correspond to commands that can be run by that utility.
    class CommandLine < Thor
        
        desc "ice FILES", "Processes ICE files into JSON that can be ingested by Solr"
        long_desc <<-LONGDESC
        `ice FILES` will read in a list of files (or from STDIN, if no files are provided) and
        convert them to concatenated JSON, sending the output to the standard output.
        LONGDESC
        option :pretty, :aliases => '-p', :type =>:boolean, :default => false, :desc => "whether to pretty-print the JSON output"
        option :valid, :aliases => '-v', :type => :boolean, :default =>false, :desc => "Whether to generate valid JSON; false means concatenated JSON"
        option :output_dir, :aliases => '-o', :type => :string, :default => nil, :desc => "Directory for output files (best to use if processing large or multiple inputs); if unset, output is sent to STDOUT"
        option :chunk_size, :aliases => '-s', :type=> :numeric, :default => 20000, :desc => "Number of records to put in each output file (requires :output_dir)"
        # Converts ICE XML files from Syndetics to JSON.  Execute +trln help ice+ for more details.
        def ice(*files)
            if options[:output_dir]
                # if we have an output directory, we should use a 'chunker'
                copts = { :dir => options[:output_dir], :chunk_size => options[:chunk_size] }
                FileUtils.mkdir_p(options[:output_dir])
                output = TRLN::Util::Chunker.new(copts)
                # 'pretty' and 'valid' are no good here, as they'll throw the chunker off
                if options[:pretty] || options[:pretty]
                    raise ValueError.new("Can't use pretty/valid options with output_dir")
                end
            else
                output = $stdout                    
            end
            processor = ICE::Processor.new(options)
            outputs.write '[' if options[:valid]
            if files.empty?
                processor.process($stdin, output)
            else 
                files.each do |file|
                    processor.process(file, output) if File.exist?(file)
                end
            end
            output.write "\n" if options[:pretty]
            output.write ']' if options[:valid]
        end

        # Convert ICE to JSON and ingest to Solr.  Execute +trln help ice_ingest+ for more details.
        desc "ice_ingest FILES", "Sends ICE JSON to Solr"
        long_desc <<-LONGDESC
        `ice_ingest FILES` takes JSON output (from, e.g. the `ice` command above) and
        ingests them into Solr.  The 'url' parameter shoud point to the base URL collection/core
        LONGDESC
        option :url, :alias => '-u', :type => :string, :default => 'http://localhost:8983/solr/', :desc => "base URL of solr server for ingest"
        option :collection, :alias => '-c', :type => :string, :default => 'icetocs'
        option :dir, :alias => '-d', :type => :string, :desc => "Directory to store intermediate files"
        option :chunk_size, :aliases => '-s', :type => :numeric, :default => 20000
        def ice_ingest(*files)
            require 'trln/util/solrclient'
            logger = Logger.new($stderr)
            logger.progname = 'trln'
            files = [ $stdin ] if files.empty?
            processor = ICE::Processor.new(pretty: false, valid: false)
            logger.info "Starting conversion to JSON"
            opts = { :chunk_size => options[:chunk_size] }
            
            if options[:dir]
                opts[:dir] = options[:dir]
            end

            chunker = TRLN::Util::Chunker.new(opts) do |output|
                    files.each do |input|
                        processor.process(input, output)
                    end
            end
            solr_url = options[:url]
            solr_url += '/' unless solr_url.end_with?('/')
            logger.info "Performing Solr update from #{chunker.files.length} files"
            client = TRLN::Util::SolrClient.new(solr_url, options[:collection]) do |client|
                logger.info "Updating #{chunker.files.length} files"
                client.json_doc_update(chunker.files)
            end
            logger.info "Done."
            chunker.cleanup
        end
    end # CommandLine
end # module
