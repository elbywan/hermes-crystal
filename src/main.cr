require "./bindings"
require "json"

module Hermes
  extend self
  include Bindings

  VERSION = "0.1.0"

  def err_check(result)
    if result == LibHermes::SnipsResult::SnipsResultKo
      LibHermes.hermes_get_last_error(out error)
      raise String.new(error)
    end
  end

  def err_check
    result = yield
    err_check(result)
  end

  options = LibHermes::CMqttOptions.new
  options.broker_address = "localhost:1883"

  # ENV["RUST_LOG"] ||= "debug"
  # err_check LibHermes.hermes_enable_debug_logs

  err_check LibHermes.hermes_protocol_handler_new_mqtt_with_options(out handler, pointerof(options), nil)
  err_check LibHermes.hermes_protocol_handler_dialogue_facade(handler, out dialogue_facade)

  # start_message = {
  #   site_id: "default",
  #   init: {
  #     init_type: LibHermes::SnipsSessionInitType::SnipsSessionInitTypeNotification,
  #     value: "Salut la compagnie!"
  #   }
  # }

  start_message = LibHermes::CStartSessionMessage.new(
    site_id: "default",
    init: LibHermes::CSessionInit.new(
      init_type: LibHermes::SnipsSessionInitType::SnipsSessionInitTypeNotification,
      value: "Salut la compagnie!".to_unsafe()
    )
  )

  err_check LibHermes.hermes_dialogue_publish_start_session(dialogue_facade, pointerof(start_message))

  sleep 2

  start_message = LibHermes::CStartSessionMessage.new(
    site_id: "default",
    init: LibHermes::CSessionInit.new(
      init_type: LibHermes::SnipsSessionInitType::SnipsSessionInitTypeAction,
      value: (
        value = LibHermes::CActionSessionInit.new(
          text: "Démarrage de la session…",
          # intent_filter: (
          #   intent_filter = LibHermes::CStringArray.new(
          #     data: ["intent"].map { |elt| elt.to_unsafe() },
          #     size: 1
          #   )
          #   pointerof(intent_filter)
          # )
        )
        pointerof(value).as(Void*)
      )
    )
  )

  err_check LibHermes.hermes_dialogue_publish_start_session(dialogue_facade, pointerof(start_message))

  LibHermes.hermes_dialogue_subscribe_intents(dialogue_facade, ->(message, data) {
    LibHermes.hermes_drop_intent_message(message)
    sleep 1
    pp message.value
    puts String.new message.value.input
  })

  sleep 60

  err_check LibHermes.hermes_drop_dialogue_facade(dialogue_facade)
  err_check LibHermes.hermes_destroy_mqtt_protocol_handler(handler)
end
