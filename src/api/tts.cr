require "../bindings"
require "./utils"

class Api::Tts
  include Bindings
  include Api::Utils

  @subscriber_sync = Mutex.new

  protected def initialize(handler, @subscriptions : Hash(String, Array(Void* -> Void)))
    call! LibHermes.hermes_protocol_handler_tts_facade(handler, out @facade)
  end

  # Publish a message to register a sound and make it useable from the tts.
  def publish_register_sound(message)
    call! LibHermes.hermes_tts_publish_register_sound(@facade, ptr_alloc RegisterSoundMessage.new(message).to_unsafe)
  end

  protected def destroy
    call! LibHermes.hermes_drop_tts_facade(@facade)
  end
end
