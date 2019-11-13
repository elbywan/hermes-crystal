require "../bindings/mappings"
require "./utils"
require "./flow"

# The Dialog facade, used to simulate dialogue rounds between the user and the action.
class Api::Dialog
  include Mappings
  include Api::Utils

  @subscriber_sync = Mutex.new

  @active_sessions = Set(String).new
  @active_sessions_lock = Mutex.new

  private def add_active_session(session_id)
    @active_sessions_lock.synchronize do
      @active_sessions << session_id
    end
  end

  private def delete_active_session(session_id)
    @active_sessions_lock.synchronize do
      @active_sessions.delete session_id
    end
  end

  protected def initialize(handler, @subscriptions : Hash(String, Array(Void* -> Void)))
    call! LibHermes.hermes_protocol_handler_dialogue_facade(handler, out @facade)
  end

  # Publish a start session message.
  def publish_start_session(message)
    call! LibHermes.hermes_dialogue_publish_start_session(@facade, ptr_alloc StartSessionMessage.new(message).to_unsafe)
  end

  # Publish a continue session message.
  def publish_continue_session(message)
    call! LibHermes.hermes_dialogue_publish_continue_session(@facade, ptr_alloc ContinueSessionMessage.new(message).to_unsafe)
  end

  # Publish an end session message.
  def publish_end_session(message)
    call! LibHermes.hermes_dialogue_publish_end_session(@facade, ptr_alloc EndSessionMessage.new(message).to_unsafe)
  end

  # Publish a dialogue configure message.
  def publish_configure(message)
    call! LibHermes.hermes_dialogue_publish_configure(@facade, ptr_alloc DialogueConfigureMessage.new(message).to_unsafe)
  end

  generate_subscriber(dialogue, "session_started", SessionStartedMessage, hermes_drop_session_started_message)
  generate_subscriber(dialogue, "session_queued", SessionQueuedMessage, hermes_drop_session_queued_message)
  generate_subscriber(dialogue, "session_ended", SessionEndedMessage, hermes_drop_session_ended_message)
  generate_subscriber(
    dialogue,
    "intent",
    IntentMessage,
    hermes_drop_intent_message,
    key_check: (
      message.intent.intent_name == extra_args[0]
    )
  )
  generate_subscriber(dialogue, "intents", IntentMessage, hermes_drop_intent_message)
  generate_subscriber(dialogue, "intent_not_recognized", IntentNotRecognizedMessage, hermes_drop_intent_not_recognized_message)

  # Create a new dialog flow having a single intent as the entry point.
  def flow(intent_name : String, &block : Flow::IntentContinuation)
    flows({intent_name, block})
  end

  # Create a new dialog flow having one or more intents as the entry point.
  def flows(*intent_descriptors)
    intent_descriptors.map do |descriptor|
      intent_name, action = descriptor
      subscriber = subscribe_intent(intent_name) do |intent_message|
        session_id = intent_message.session_id
        unless @active_sessions.includes? session_id
          add_active_session session_id
          cleanup_listener = uninitialized Void* -> Void
          cleanup_listener = subscribe_session_ended do |session_ended_message|
            if session_ended_message.session_id == session_id
              delete_active_session session_id
              unsubscribe_session_ended cleanup_listener
            end
          end
          flow = Flow.new(self, session_id)
          tts = action.call(intent_message, flow)
          flow.end_round(tts)
        end
      end
      {intent_name, subscriber}
    end
  end

  # Dispose previously defined flows.
  def dispose_flows(registered_flows)
    registered_flows.each { |flow|
      intent_name, subscriber = flow
      unsubscribe_intent(subscriber, intent_name)
    }
  end

  # Destroy the facade.
  protected def destroy
    call! LibHermes.hermes_drop_dialogue_facade(@facade)
  end
end
