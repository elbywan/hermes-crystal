require "../bindings"
require "./utils"

class Api::Tts
  include Bindings
  include Api::Utils

  protected def initialize(handler, @subscriptions : Hash(String, Array(Void*)))
    call! LibHermes.hermes_protocol_handler_tts_facade(handler, out @facade)
  end

  # Publish a message to register a sound and make it useable from the tts.
  def publish_register_sound(message)
    call! LibHermes.hermes_tts_publish_register_sound(@facade, message)
  end

  protected def destroy
    call! LibHermes.hermes_drop_tts_facade(@facade)
  end
end
