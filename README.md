# Autoprotocol Ruby Library

[Autoprotocol](http://www.autoprotocol.org) is a standard way to express
experiments in life science. This repository contains a Ruby library for
generating Autoprotocol.

This library is heavily inspired from the [Python Autoprotocol library](https://github.com/autoprotocol/autoprotocol-python)

## Installation
To install, simply:

    `gem install autoprotocol`

### Bundler
Or you can install via bundler with the following addition to
your `Gemfile`:

    source 'https://rubygems.org'

    gem 'autoprotocol'

## Requirements
- Ruby 2.0.0 or above

## Status
Only some of the autoprotocol spec has been currently implemented. If there's a
portion missing that you need, open an issue or even better open a pull request.

### Instructions implemented
[x] Dispense
[x] Incubate
[ ] Distribute
[ ] Cover

## Building a Protocol
A basic protocol object has empty "refs" and "instructions" stanzas.  Various
helper methods in the Protocol class are used to append Instructions and Refs
to the Protocol object such as in the simple protocol below:

```ruby
require 'json'
require 'autoprotocol'

# instantiate new Protocol Object
protocol = Protocol.new

# append refs (containers) to Protocol object
bacteria = protocol.ref('bacteria', cont_type: '96-pcr', storage: 'cold-4')
media = protocol.ref('media', cont_type: 'micro-1.5', storage: 'cold-4')
reaction_plate = protocol.ref('reaction_plate', cont_type: '96-flat', storage: 'warm_37')

...
```

## Development
The tests can be run with `bundle exec rake test`
