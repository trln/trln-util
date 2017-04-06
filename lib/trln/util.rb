require "trln/util/meta"
require 'trln/util/loggable'
require 'trln/util/commandline'

module TRLN
    module Util

        # gets a  `:read` able object from a number of different
        # input types.  Convenience method
       def self.get_readable(something)
            result = nil
            if something.respond_to?(:read)
                result = something
            else
                if File.exist?(something)
                    the_io = File.open(something)
                    case something
                        when /\.gz$/ then 
                            result = Zlib::GzipReader.wrap(the_io)
                        else 
                            result = the_io
                    end
                else
                    raise "Unable to read #{something}" if result.nil?
                end
            end
            if block_given?
                begin
                    yield result 
                 ensure   
                    result.close
                end
            end
            result
        end

        # Locates resources packaged with the gem (e.g. default documents, etc.) 
        def self.find_resources(*resources)
            res_dir = File.join(File.dirname(__FILE__), '../../resources')
            base = File.expand_path(res_dir)
            resources.collect do |r|
                File.join(base, r)
            end
        end
    end # Util
end #TRLN