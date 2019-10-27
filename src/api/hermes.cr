require "../bindings/mappings"
require "./dialog"
require "./injection"
require "./feedback"
require "./tts"

# Hermes-crystal is an high level API that allows you to
# subscribe and send Snips messages using the Hermes protocol.
class Hermes
  include Mappings
  include Bindings
  include Api

  # Internal

  @handler : LibHermes::CProtocolHandler*?
  @subscriptions : Hash(String, Array(Void*))

  # Facades

  # Return a Dialog facade instance used to interact with the dialog API.
  getter(dialog) {
    Dialog.new(@handler, @subscriptions)
  }
  # Return an Injection facade instance used to interact with the injection API.
  getter(injection) {
    Injection.new(@handler, @subscriptions)
  }
  # Return a Feedback facade instance used to interact with the feedback API.
  getter(feedback) {
    Feedback.new(@handler, @subscriptions)
  }
  # Return a Tts facade instance used to interact with the tts API.
  getter(tts) {
    Tts.new(@handler, @subscriptions)
  }

  # Utils

  # Enable printing extra debug logs.
  def self.enable_debug_log
    ENV["RUST_LOG"] ||= "debug"
    Bindings.call! LibHermes.hermes_enable_debug_logs
  end

  # Lifecycle

  # Create a new Hermes instance that connects to the underlying event bus.
  def initialize(**options)
    mqttOptions = MqttOptions.new(**options).to_unsafe
    @subscriptions = {} of String => Array(Void*)
    boxed_subscriptions = Box.box(@subscriptions)
    call! LibHermes.hermes_protocol_handler_new_mqtt_with_options(out handler, pointerof(mqttOptions), boxed_subscriptions)
    @handler = handler
  end

  # Disposes the hermes object and its underlying resources.
  def finalize
    destroy
  end

  # Disposes the hermes object and its underlying resources.
  def destroy
    @dialog.try &.destroy
    @feedback.try &.destroy
    @injection.try &.destroy
    @tts.try &.destroy

    call! LibHermes.hermes_destroy_mqtt_protocol_handler(@handler)

    @handler = nil
  end
end
