module Api::Utils
  macro generate_subscriber(facade, topic, message, drop, key_check = nil)
    # Subscribe to {{topic.id}} events.
    def subscribe_{{topic.id}}(*extra_args, once = false, &callback : {{message}} -> Void)
      @subscriber_sync.synchronize do
        %key = {{ topic }}
        subscriber = uninitialized Void* -> Void
        subscriber = ->(c_message: Void*) {
          if Thread.current.event_base.nil?
            pp Thread.current
            raise "Subscriber is not running in a Crystal thread…"
          end
          message = {{message}}.new c_message.as(LibHermes::C{{message}}*).value
          {% if key_check %}
            unless {{ key_check }}
              return
            end
          {% end %}
          callback.call(message)
          @subscriber_sync.synchronize do
            @subscriptions[%key].delete(subscriber) if once
          end
        }

        unless @subscriptions.has_key? %key
          @subscriptions[%key] = [] of Void* -> Void
          dispatcher = ->(message: LibHermes::C{{message}}*, user_data : Void*) {
            GC.disable # Disabling GC because this callback runs inside a thread spawned by the hermes code.
            cleanup = -> {
              LibHermes.{{drop}}(message)
              nil
            }
            Box((Void*, String, -> Void) -> Void).unbox(user_data).call(message.as(Void*), {{ topic }}, cleanup)
            GC.enable # Re-enabling GC.
            Process.kill(Signal::USR1, Process.pid)
          }
          call! LibHermes.hermes_{{ facade }}_subscribe_{{topic.id}}(@facade, *extra_args, dispatcher)
        end

        @subscriptions[%key] << subscriber
        subscriber
      end
    end

    # Unsubscribe to {{topic.id}} events.
    def unsubscribe_{{topic.id}}(callback_ref, *extra_args)
      @subscriber_sync.synchronize do
        %key = {{ topic }}
        @subscriptions[%key].delete(callback_ref)
      end
    end
  end
end
