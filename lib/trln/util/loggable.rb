require 'logger'

module TRLN::Util
    # Mixin for logging standardization
    module Loggable

        # Configure a logger based on a set of options.  The default (empty options), returns 
        # a Logger instance  with INFO level that sends output to +$stderr+.  Most options allow
        # customizing these defaults (destination, log level).
        # 
        # @param [Hash] options a set of logging options
        # @option options [Logger] :logger a pre-configured logger.  If this value is provided, it will be the return value from this
        #    method
        # @option options [Boolean] :verbose set  logging level to Logger.DEBUG
        # @option options [Boolean] :quiet set logging level to Logger.ERROR
        # @option options [Boolean] :silent disable all logging output.  If this option is present it will
        #  override *all* other options.
        # @option options [String] :logfile name of file for output; default is +$stderr+
        # @option options [String] :progname the name to provide as Logger.progname --
        #   default is to use the name of the including class.
        def get_logger(options={})
            return options[:logger] if options.key?(:logger)

            dest = $stderr
            level = Logger::INFO

            level = Logger::DEBIG if options[:verbose]
            level = Logger.ERROR if options[:quiet] 

            dest = options[:logfile] if options [:logfile]
            dest = (File.exist?('/dev/null') ? '/dev/null' : 'NUL') if options[:silent]

            progname = options[:progname] || self.class.name
            
            logger = Logger.new(dest)
            logger.progname = progname
            logger.level = level
            logger
        end
    end
end
