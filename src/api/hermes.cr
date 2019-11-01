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

  alias UserData = Void*, String -> Nil

  @handler : LibHermes::CProtocolHandler*?
  @subscriptions : Hash(String, Array(Void* -> Void))
  @dispatcher_channel = Channel({Void*, String}?).new
  @sync_channel = Channel(Nil).new
  @user_data : UserData
  @boxed_user_data : Pointer(Void)

  # Lifecycle

  # Create a new Hermes instance that connects to the underlying event bus.
  def initialize(**options)
    mqttOptions = MqttOptions.new(**options).to_unsafe
    @subscriptions = {} of String => Array(Void* -> Void)

    spawn same_thread: true do
      loop do
        begin
          # puts "6. before channel receive"
          # STDOUT.flush
          payload = @dispatcher_channel.receive
          if Thread.current.event_base.nil?
            pp Thread.current
            raise "Subscriber is not running in a Crystal thread…"
          end
          # pp Thread.current
          # STDOUT.flush
          # puts "3. after channel receive"
          # STDOUT.flush
          if payload
            msg_ptr, topic = payload # .dup
            # puts "4. before subscription called"
            # STDOUT.flush
            subscriptions = @subscriptions[topic].dup
            subscriptions.each &.call(msg_ptr)
            # puts "5. after subscription called"
            # STDOUT.flush
          else
            break
          end
        rescue ex
          STDERR.puts "Error while dispatching the hermes message to registered subscribers."
          STDERR.puts ex
        end
        @sync_channel.send nil
      end
    end

    @user_data = ->(msg_ptr : Void*, topic : String) {
      # puts "(dispatcher) 1. before send"
      # STDOUT.flush
      begin
        @dispatcher_channel.send({msg_ptr, topic})
        # puts "(dispatcher) 2. after send & before yield"
        # STDOUT.flush
        GC.enable
        Fiber.yield
        @sync_channel.receive
        GC.disable
      rescue ex
        STDERR.puts "Error while dispatching the hermes message to registered subscribers."
        STDERR.puts ex
      end
    # puts "(dispatcher) 7. after user data send & yield"
    # STDOUT.flush
    }
    # Prevent GC
    @boxed_user_data = Box.box(@user_data)

    call! LibHermes.hermes_protocol_handler_new_mqtt_with_options(out handler, pointerof(mqttOptions), @boxed_user_data)
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
end
