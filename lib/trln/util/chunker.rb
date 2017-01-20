require 'trln/util/packager'
require 'tmpdir'

module TRLN
    module Util
        
        # IO/File -like writeable object that automatically manages rotation
        # of output to multiple files, based
        # on the number of records written.  
        # Each call to `#write(rec)`
        # writes an individual record to the current output file.
        class Chunker
            include Packager

            DEFAULTS = {
                :chunk_size => 20000,
            }

            attr_reader :files, :count, :chunk_size, :dir

           
            # Create a new chunker
            # @param options [Hash]
            # @option options [String] chunk_size the maximum number of records to write to each file
            # @option options [String] transaction_id an (optional) transaction ID to be used in the creation of a temporary directory
            # @option options [Dir] dir an optional directory to store the output files.  If not provided, a temporary directory will be created.
            # @option options [#call(int)] namer a callable that produces filenames given the number of the file we're currently processing
            # @option options [String] transaction_id a transaction ID, which will be used as a component of a temporary directory name to 
            #    aid in debugging.
            # Note that, when using a temporary directory, that directory
            # will be removed when the object is garbage collected.  
            # You will need to process the results before this happens!
            # @see #package(filename)
            def initialize(options={})
                @files = []
                @count = 0
                options = Marshal.load(Marshal.dump(DEFAULTS)).update(options)
                @chunk_size = options[:chunk_size]
                @current_file = nil
                @is_tempdir = false
                @dir = options[:dir]
                @namer = options[:namer] ||  lambda do  |n| "solr-out-#{n}.json" end
                
                unless @dir
                    @is_tempdir = true
                    txn_id = options[:transaction_id] || 'unknown-tx'
                    @dir = Dir.mktmpdir("chunker-#{txn_id}-")
                    ObjectSpace.define_finalizer(self, proc { FileUtils.remove_entry @dir })
                end

                if block_given?
                    yield self
                    finish_currentfile
                end
                self
            end

            def next_file
                fn = @namer.call(@files.length+1)
                full_path = File.join(@dir, fn)
                @files << full_path
                @current_file = File.open(full_path, 'w')
            end 

            def finish_currentfile
                @current_file.flush
                @current_file.close            
                @current_file = nil
            end

            # Writes an individual record to the output
            # Each call to this method increments the overall count,
            # and so calling this method may have the side effect of closing the
            # current output file and opening a new one.
            # @param rec [Object] the record to be written
             def write(rec)
                next_file if @current_file.nil?
                @current_file.write(rec)
                finish_currentfile if (@count += 1) % @chunk_size == 0
            end

            # Deletes any files created by this chunker.
            def cleanup
                @files.each do |f|
                    File.unlink(f) if File.exist?(f)
                end
                Dir.rmdir(@dir) if @is_tempdir
            end

            private :finish_currentfile
            alias_method :close, :finish_currentfile
            public :close
        end
    end
end
