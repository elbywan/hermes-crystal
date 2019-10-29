require "../bindings/mappings"
require "./utils"

class Api::Dialog
  include Mappings
  include Api::Utils

  protected def initialize(handler, @subscriptions : Hash(String, Array(Void*)))
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
  generate_subscriber(dialogue, "intent", IntentMessage, hermes_drop_intent_message)
  generate_subscriber(dialogue, "intents", IntentMessage, hermes_drop_intent_message)
  generate_subscriber(dialogue, "intent_not_recognized", IntentNotRecognizedMessage, hermes_drop_intent_not_recognized_message)

  # Destroy the facade.
  protected def destroy
    call! LibHermes.hermes_drop_dialogue_facade(@facade)
  end
end
