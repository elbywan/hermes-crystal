# hermes-crystal

#### A crystal wrapper around the hermes protocol

[![Docs](https://img.shields.io/badge/docs-available-brightgreen.svg)](https://elbywan.github.io/hermes-crystal/)
[![GitHub release](https://img.shields.io/github/release/elbywan/hermes-crystal.svg)](https://github.com/elbywan/hermes-crystal/releases)
[![Build Status](https://travis-ci.org/elbywan/hermes-crystal.svg?branch=master)](https://travis-ci.org/elbywan/hermes-crystal)

## Context

The `hermes-crystal` library provides bindings for the [Hermes protocol](https://docs.snips.ai/reference/hermes) that [Snips](https://snips.ai/) components use to communicate together. `hermes-crystal` allows you to interface seamlessly with the Snips platform and create Voice applications with ease!

`hermes-crystal` abstracts away the connection to the MQTT bus and the parsing of incoming and outcoming messages from and to the components of the platform and provides a high-level API as well.

## Installation

1. Add the dependency to your `shard.yml`:

```yaml
dependencies:
  hermes-crystal:
    github: elbywan/hermes-crystal
```

2. Run `shards install`

A postinstall script will automagically download the file if your os and architecture is supported.

#### ⚠️ Unsupported platforms / architectures

If the setup could not infer the library file version, it will attempt to build it from the sources.
Please note that [`rust`](https://www.rust-lang.org/tools/install) and [`git`](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) are required in order to build the library.

If you want to force this behaviour, you can also define the `HERMES_BUILD_FROM_SOURCES` environment variable before running `shards install`.

```sh
env HERMES_BUILD_FROM_SOURCES=true shards install
```

## Usage

```crystal
require "hermes-crystal"
```

### Minimal use case

```crystal
require "hermes-crystal"

# Instantiate a Hermes object connecting to the default MQTT address.
hermes = Hermes.new broker_address: "localhost:1883"

hermes.dialog.flow "myIntent" do |msg, flow|
  # Log the message
  pp msg
  # End the session and speak
  "Received message for intent #{msg.intent.intent_name}"
end

# To prevent the process from exiting, if needed, you can use `sleep`.
sleep
```

### Expanded use case

#### High level "flow" API.

```crystal
require "hermes-crystal"

hermes = Hermes.new broker_address: "localhost:1883"

# NB: dialog is only one of the available API facades.
dialog = hermes.dialog

# Using the high level API is strongly recommended for building complex dialog flows.

# Let's register the following dialog paths:
# A
# ├── B
# │   └─ D
# └── C
#
# In plain words, intent 'A' starts the flow, then for the next round possible intents are 'B' or 'C'.
# If 'B' is the next intent detected, then the following intent must be 'D' and then the flow will end.
# If 'C' is the next intent, the flow will end.

dialog.flow "A" do |_, flow|
  puts "Intent A received. Session started."

  # At each step of the dialog flow, you have the choice of
  # registering the next intents, or end the flow by not
  # registering any continuations.

  # We choose to subscribe to both intent B or C so that the dialog
  # flow will continue with either one or the other next.

  # Mark intent 'B' as one of the next dialog intents. (A -> B)
  flow.continue "B" do |_, flow|
    puts "Intent B received. Session continued."

    # Mark intent 'D'. (A -> B -> D)
    flow.continue "D" do |_, flow|
        puts "Intent D received."
        "Finished the session with intent D."
    end

    # Make the TTS say that.
    "Continue with D."
  end

  # Mark intent 'C' as one of the next dialog intents. (A -> C)
  flow.continue "C" do |msg, flow|
      slot_value = msg.slots.try &.[0].value.value
      puts "Intent C received."
      "Finished the session with intent C having value #{slot_value} ."
  end

  # A flow function must return a string that is going to be spoken by the TTS.
  "Continue with B or C."
end
```

#### Low level subscriber / publisher API.

```crystal
require "hermes-crystal"

hermes = Hermes.new broker_address: "localhost:1883"

# NB: dialog is only one of the available API facades.
dialog = hermes.dialog

# Every API facade can publish and receive data based on a list of events.

# For the purpose of this example, we will only use the dialog facade, and the
# events related to a dialog session.

# Note that more events are available for each facade.

# You can subscribe to an event triggered when the intent 'some_intent' is detected like this:
dialog.subscribe_intent "some_intent" do |message|
  # The 'message' argument contain all the data you need to perform an action based on what the user said.

  # For instance, you can grab a slot and its value like this.
  my_slot = message.slots.try &.find { |slot| slot.slot_name == "some_slot" }
  slot_value = my_slot.try &.value.value
  puts "Slot value: #{slot_value}"
  # And here is how to grab the intent name.
  puts "Received intent: #{message.intent.intent_name}"

  session_must_be_continued = true
  # Then, you can either (but not both!):
  if session_must_be_continued
    # Continue the current dialogue session.
    dialog.publish_continue_session({
      # Session id is the same as the current session.
      session_id: message.session_id,
      # This is what is going to be spoken between this and the next session round.
      text: "The session lives on…",
      # A list of possible intent continuations for the next round.
      intent_filter: ["next_intent"],
      # Unused by the crystal wrapper.
      custom_data: nil,
      # An optional slot filler argument. Unneeded for this example.
      slot: nil,
      # If true, then a custom behaviour can be determined if no intents are recognized for the next round of dialogue.
      send_intent_not_recognized: false
    })
  else
    # End the dialogue session.
    dialog.publish_end_session({
      session_id: message.session_id,
      text: "The session has ended."
    })
  end
end

# You can also unsubscribe to a registered event.
handler = uninitialized Void* -> Void
handler = dialog.subscribe_intents {
    # In this case, unsubscribe the first time an intent has been detected.
    dialog.unsubscribe_intents handler
    # ...
}
# Or process a subscription only once:
dialog.subscribe_intents once: true {
  # ...
}
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
