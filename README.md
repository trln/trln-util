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

To install from source, clone this repository and then execute:

    $ rake install

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

However, the 'ice' tool is also capable of reading gzipped files, so the above
is equivalent to:


    $ trln ice -o ice_json TOC_Full_20172222.1.xml.gz > ingest.json

## Solr Schema

The `solrtask` gem includes commands for harmonizing a schema for a core or
collection that was creating using the 'basic_configs' template.  The input to
this command is a YAML file; `resources/ice-schema.yaml` in the source
distribution contains the definition of the Solr schema that matches the output
of the tools in this gem.  Assuming the `solrtasks` gem is already installed, and that you have checked the source for this gem into your directory:

    $ solrtask create-collection icetocs
    $ solrtask harmonize-schema icetocs resources/ice-schema.yaml

You should then be able to ingest docuemnts into the 'icetocs' schema using the
tools provided in this gem.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/trln/trln-util

