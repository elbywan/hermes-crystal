require "../bindings"
require "./utils"

class Api::Tts
    include Bindings
    include Api::Utils

    def initialize(handler, @subscriptions : Hash(String, Array(Void*)))
        call! LibHermes.hermes_protocol_handler_tts_facade(handler, out @facade)
    end

    def publish_register_sound(message)
        call! LibHermes.hermes_tts_publish_register_sound(@facade, message)
    end

    def destroy
        call! LibHermes.hermes_drop_tts_facade(@facade)
    end
end