require "../bindings/mappings"
require "./dialog"
require "./injection"
require "./feedback"
require "./tts"

# Unfortunately needed to enqueue the subscriber fiber in the main thread scheduler.
# :nodoc:
class Crystal::Scheduler
  def enqueue(fiber : Fiber) : Nil
    previous_def
  end
end

# Used to resume the main event loop when a subscriber kick in.
Signal::USR1.trap do
  Fiber.yield
end

# Hermes-crystal is an high level API that allows you to
# subscribe and send Snips messages using the Hermes protocol.
class Hermes
  include Mappings
  include Bindings
  include Api

  # Internal

  alias UserData = Void*, String, -> Void -> Nil

  @handler : LibHermes::CProtocolHandler*?
  @subscriptions : Hash(String, Array(Void* -> Void))
  @user_data : UserData
  @boxed_user_data : Pointer(Void)
  @active_fibers : Array(Fiber) = [] of Fiber
  @parent_thread : Thread

  # Lifecycle

  # Create a new Hermes instance that connects to the underlying event bus.
  def initialize(**options)
    mqttOptions = MqttOptions.new(**options).to_unsafe
    @subscriptions = {} of String => Array(Void* -> Void)

    @parent_thread = Thread.current

    @user_data = ->(msg_ptr : Void*, topic : String, cleanup : -> Void) {
      fiber = uninitialized Fiber
      fiber = Fiber.new "User data fiber" do
        begin
          if @parent_thread != Thread.current
            pp Thread.current
            pp @parent_thread
            raise "This code should run on the main thread, but does not for some reason."
          end
          subscriptions = @subscriptions[topic].dup
          subscriptions.each &.call(msg_ptr)
        rescue ex
          STDERR.puts ex
        ensure
          cleanup.call
          @active_fibers.delete fiber
        end
      end
      fiber.@current_thread.set @parent_thread
      @parent_thread.scheduler.enqueue fiber
      @active_fibers << fiber
    }

    # Prevent GC collecting the box
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
