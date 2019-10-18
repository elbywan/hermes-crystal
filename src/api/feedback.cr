require "../bindings"
require "./utils"

class Api::Feedback
  include Bindings
  include Api::Utils

  def initialize(handler, @subscriptions : Hash(String, Array(Void*)))
    call! LibHermes.hermes_protocol_handler_sound_feedback_facade(handler, out @facade)
  end

  def publish_toggle_on(message)
    call! LibHermes.hermes_sound_feedback_publish_toggle_on(@facade, message)
  end

  def publish_toggle_off(message)
    call! LibHermes.hermes_sound_feedback_publish_toggle_off(@facade, message)
  end

  def destroy
    call! LibHermes.hermes_drop_sound_feedback_facade(@facade)
  end
end
