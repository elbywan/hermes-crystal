require "../bindings/mappings"
require "./dialog"
require "./injection"
require "./feedback"
require "./tts"

# Unfortunately, this override is needed to enqueue the subscriber fiber in the main thread scheduler.
# :nodoc:
class Crystal::Scheduler
  def enqueue(fiber : Fiber) : Nil
    previous_def
  end
end

# Used to resume the main event loop when a subscriber kicks in.
Signal::USR1.trap do
  # Force garbage collection in the main thread,
  # prevents further issues caused by the fact that
  # the hermes lib spawns its own threads.
  GC.collect
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

  # Helper

  # Creates a new hermes instance and yields it to the block.
  # When the proc returns, gracefully destroy the underlying resources.
  #
  # ```
  # Hermes.with_hermes broker_address: "localhost:1883" do |hermes|
  #   # do stuff…
  #   sleep # or wait for something to finish
  # end
  # ```
  def self.with_hermes(**options, &)
    hermes = Hermes.new **options
    begin
      yield hermes
    rescue ex
      STDERR.puts ex
    ensure
      hermes.destroy
    end
  end

  # Lifecycle

  # Create a new Hermes instance that connects to the underlying event bus.
  #
  # ```
  # hermes = Hermes.new broker_address: "localhost:1883"
  # ```
  def initialize(**options)
    mqtt_options = MqttOptions.new(**options).to_unsafe
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

    call! LibHermes.hermes_protocol_handler_new_mqtt_with_options(out handler, pointerof(mqtt_options), @boxed_user_data)
    @handler = handler
  end

  # Disposes the hermes object and its underlying resources.
  def finalize
    destroy
  end

  # Disposes the hermes object and its underlying resources.
  def destroy
    @dialog.try &.destroy
    @dialog = nil
    @feedback.try &.destroy
    @feedback = nil
    @injection.try &.destroy
    @injection = nil
    @tts.try &.destroy
    @tts = nil

    call! LibHermes.hermes_destroy_mqtt_protocol_handler(@handler) if @handler

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
