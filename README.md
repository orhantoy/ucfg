# ucfg - Universal Configuration

Configuration file validation with JSON Schema. Inspired by [elastic/go-ucfg](https://github.com/elastic/go-ucfg).

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'ucfg'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ucfg

## Usage
This section shows schema example using different validations

{   
     "properties": {
      "required": ["name"],
      "properties": {
        "name": {
          "type": "string"
        },
        "color": {
          "type": "string",
          "enum": ["red", "green", "blue"],
          "const": "red"
        },
        "a": {
          "min": -20,
          "max": 3
        }
        "enabled": {
          "type": "boolean"
        }
      }
    }
}


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## JSON Schema Support

This part covers the validations that this gem doesnot support

{"type": "string"} 
X minLength
X maxLength
X pattern

{"type": "number"}
X multipleOf
X range (exclusiveMinimum, exclusiveMaximum)

{"type": "array"}
X minItems
X maxItems
X uniqueItems

{"type": "object"}
X pattern
X patternProperties
X minProperties
X maxProperties
X dependencies
X builtin

## Contributing

Inital version of this gem was developed with the help of https://github.com/SwathiSankararaman who is a part of https://github.com/HackYourFuture-CPH

Bug reports and pull requests are welcome on GitHub at https://github.com/orhantoy/ucfg.
