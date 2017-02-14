$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift File.expand_path('data', __FILE__)

require 'trln/util'

module TestUtil
    def load_data(filename)
        the_file = $LOAD_PATH.collect { |x| 
            File.join(x, filename)
        }.find{ |f| File.exist?(f) }
        if the_file
            data = File.read(the_file)
            if block_given?
                yield data
            else
                data
            end
        end
    end
end



