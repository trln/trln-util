require 'rubygems/package'

module TRLN::Util
    module Packager
        # outputs the files in the +files+ attribute 
        # as a tarball with the given name
        # @param filename [String] the complete path of the output file
        def package(filename)
            File.open(filename, 'wb') do |file|
                Zlib::GzipWriter.wrap(file) do |gz|
                    Gem::Package::TarWriter.new(gz) do |tar|
                        @files.each do |packaged_file|
                            name = File.basename(packaged_file)
                            length = File.size?(packaged_file)
                            if length > 0
                                tar.add_file_simple(name, 0444,length) do |io|
                                    io.write(File.open(packaged_file).read)
                                end
                            end
                        end # @files
                    end # tar
                end # gzip 
            end # File
            @files.collect { |f| File.basename(f) }
        end # package method
    end # Package module
end # TRLN::Util
