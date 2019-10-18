require "../bindings"
require "./utils"

class Api::Injection
  include Bindings
  include Api::Utils

  def initialize(handler, @subscriptions : Hash(String, Array(Void*)))
    call! LibHermes.hermes_protocol_handler_injection_facade(handler, out @facade)
  end

  def publish_injection_request(message)
    call! LibHermes.hermes_injection_publish_injection_request(@facade, message)
  end

  def publish_injection_reset_request(message)
    call! LibHermes.hermes_injection_publish_injection_reset_request(@facade, message)
  end

  def publish_injection_status_request
    call! LibHermes.hermes_injection_publish_injection_status_request(@facade)
  end

  generate_subscriber(injection, "injection_complete", CInjectionComplete, hermes_drop_injection_complete_message)
  generate_subscriber(injection, "injection_reset_complete", CInjectionResetComplete, hermes_drop_injection_reset_complete_message)
  generate_subscriber(injection, "injection_status", CInjectionStatus, hermes_drop_injection_status_message)

  def destroy
    call! LibHermes.hermes_drop_injection_facade(@facade)
  end
end
