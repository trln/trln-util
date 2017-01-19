# trln-util

Command line utilities and libraries for handling ancillary data formats
in the TRLN shared index project.

## Installation

To use within a project or Rails application, add this to your Gemfile:

```ruby
gem 'trln-util'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install trln-util

## Usage

The primary entry point for this gem is the `trln` command-line script.  It accepts a number of commands:

| Command | Purpose | Notes
| --- | --- | --- |
| `ice` | Converts ICE XML from Syndetics to JSON format | see help |
| `ice_ingest` | Converts ICE XML to JSON and ingests to Solr | see help |

Help for any of the above commands is available by passing the `help` command to the `trln` executable, e.g.

    $ trln help ice

This will show a complete list of available options and behavior.

Commands have been largely designed to work in the standard UNIX fashion,
expecting input on the standard input and sending output to the standard
output.  This makes it possible to use `trln` as a processing component in a
pipeline, e.g.

    $ gunzip -c TOC_Full_20172222.1.xml.gz | trln ice -o ice_json > ingest.json

Will convert the records in the input file and place them in the `ingest.json` file.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trln/trln-util

