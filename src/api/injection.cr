require "../bindings"
require "./utils"

class Api::Injection
  include Bindings
  include Api::Utils

  @subscriber_sync = Mutex.new

  protected def initialize(handler, @subscriptions : Hash(String, Array(Void* -> Void)))
    call! LibHermes.hermes_protocol_handler_injection_facade(handler, out @facade)
  end

  # Publish a request to inject data.
  def publish_injection_request(message)
    call! LibHermes.hermes_injection_publish_injection_request(@facade, ptr_alloc InjectionRequestMessage.new(message).to_unsafe)
  end

  # Publish a message to reset the previously injected data.
  def publish_injection_reset_request(message)
    call! LibHermes.hermes_injection_publish_injection_reset_request(@facade, ptr_alloc InjectionResetRequestMessage.new(message).to_unsafe)
  end

  # Publish a message a request a status update for a pending injection.
  def publish_injection_status_request
    call! LibHermes.hermes_injection_publish_injection_status_request(@facade)
  end

  generate_subscriber(injection, "injection_complete", InjectionCompleteMessage, hermes_drop_injection_complete_message)
  generate_subscriber(injection, "injection_reset_complete", InjectionResetCompleteMessage, hermes_drop_injection_reset_complete_message)
  generate_subscriber(injection, "injection_status", InjectionStatusMessage, hermes_drop_injection_status_message)

  protected def destroy
    call! LibHermes.hermes_drop_injection_facade(@facade)
  end
end
