# hermes-crystal

#### A crystal wrapper around the hermes protocol

## Context

The `hermes-crystal` library provides bindings for the Hermes protocol that Snips components use to communicate together. `hermes-crystal` allows you to interface seamlessly with the Snips platform and create Voice applications with ease!

`hermes-crystal` abstracts away the connection to the MQTT bus and the parsing of incoming and outcoming messages from and to the components of the platform and provides a high-level API as well.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  hermes-crystal:
    github: elbywan/hermes-crystal
```

2. Run `shards install`

## Usage

```crystal
require "hermes-crystal"
```

## Documentation

Hosted [here](https://elbywan.github.io/hermes-crystal).

## Development

#### Prerequisite

[`Rust`](https://www.rust-lang.org/learn/get-started) is needed to build the hermes library.

#### Setup

1. Clone the repo.
2. Update the hermes-protocol submodule (`git submodule update`)
3. Build the shared libraries. (`cd hermes-protocol; cargo build -p hermes-mqtt-ffi -p hermes-ffi-test; cd ..`)

#### Tasks

Development tasks are defined in the [`sam.cr`](https://github.com/imdrasil/sam.cr) file.

Use `make sam help` to display the list of available tasks.

## Contributing

1. Fork it (<https://github.com/elbywan/hermes-crystal/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [elbywan](https://github.com/elbywan) - creator and maintainer
