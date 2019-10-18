require "../bindings/mappings"
require "./dialog"
require "./injection"
require "./feedback"
require "./tts"

class Hermes
  include Mappings
  include Bindings
  include Api

  # Internal

  @handler : LibHermes::CProtocolHandler*?
  @subscriptions : Hash(String, Array(Void*))

  # Facades

  getter(dialog) {
    Dialog.new(@handler, @subscriptions)
  }
  getter(injection) {
    Injection.new(@handler, @subscriptions)
  }
  getter(feedback) {
    Feedback.new(@handler, @subscriptions)
  }
  getter(tts) {
    Tts.new(@handler, @subscriptions)
  }

  # Utils

  def self.enable_debug_log
    ENV["RUST_LOG"] ||= "debug"
    Bindings.call! LibHermes.hermes_enable_debug_logs
  end

  # Lifecycle

  def initialize(**options)
    mqttOptions = MqttOptions.new(**options).to_unsafe
    @subscriptions = {} of String => Array(Void*)
    boxed_subscriptions = Box.box(@subscriptions)
    call! LibHermes.hermes_protocol_handler_new_mqtt_with_options(out handler, pointerof(mqttOptions), boxed_subscriptions)
    @handler = handler
  end

  def finalize
    destroy
  end

  def destroy
    @dialog.try &.destroy
    @feedback.try &.destroy
    @injection.try &.destroy
    @tts.try &.destroy

    call! LibHermes.hermes_destroy_mqtt_protocol_handler(@handler)

    @handler = nil
  end
end
