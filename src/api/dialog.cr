require "../bindings"
require "./utils"

class Api::Dialog
    include Bindings
    include Api::Utils

    def initialize(handler, @subscriptions : Hash(String, Array(Void*)))
        call! LibHermes.hermes_protocol_handler_dialogue_facade(handler, out @facade)
    end

    def publish_start_session(message)
        call! LibHermes.hermes_dialogue_publish_start_session(@facade, message)
    end

    def publish_continue_session(message)
        call! LibHermes.hermes_dialogue_publish_continue_session(@facade, message)
    end

    def publish_end_session(message)
        call! LibHermes.hermes_dialogue_publish_end_session(@facade, message)
    end

    def publish_configure(message)
        call! LibHermes.hermes_dialogue_publish_configure(@facade, message)
    end

    generate_subscriber(dialogue, "session_started", CSessionStarted, hermes_drop_session_started_message)
    generate_subscriber(dialogue, "session_queued", CSessionQueued, hermes_drop_session_queued_message)
    generate_subscriber(dialogue, "session_ended", CSessionEnded, hermes_drop_session_ended_message)
    generate_subscriber(dialogue, "intent", CIntentMessage, hermes_drop_intent_message)
    generate_subscriber(dialogue, "intents", CIntentMessage, hermes_drop_intent_message)
    generate_subscriber(dialogue, "intent_not_recognized", CIntentNotRecognizedMessage, hermes_drop_intent_not_recognized_message)

    def destroy
        call! LibHermes.hermes_drop_dialogue_facade(@facade)
    end
end