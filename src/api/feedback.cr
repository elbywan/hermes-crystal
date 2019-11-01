require "../bindings"
require "./utils"

class Api::Feedback
  include Bindings
  include Api::Utils

  @subscriber_sync = Mutex.new

  protected def initialize(handler, @subscriptions : Hash(String, Array(Void* -> Void)))
    call! LibHermes.hermes_protocol_handler_sound_feedback_facade(handler, out @facade)
  end

  # Publish a message that toggles on the feedback sound.
  def publish_toggle_on(message)
    call! LibHermes.hermes_sound_feedback_publish_toggle_on(@facade, ptr_alloc SiteMessage.new(message).to_unsafe)
  end

  # Publish a message that toggles off the feedback sound.
  def publish_toggle_off(message)
    call! LibHermes.hermes_sound_feedback_publish_toggle_off(@facade, ptr_alloc SiteMessage.new(message).to_unsafe)
  end

  protected def destroy
    call! LibHermes.hermes_drop_sound_feedback_facade(@facade)
  end
end
