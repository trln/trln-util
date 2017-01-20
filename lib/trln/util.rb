require "trln/util/meta"
require 'trln/util/loggable'
require 'trln/util/commandline'

module TRLN
    module Util
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