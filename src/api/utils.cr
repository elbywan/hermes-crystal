module Api::Utils
  macro generate_subscriber(facade, topic, message, drop)
    # Subscribe to {{topic.id}} events.
    def subscribe_{{topic.id}}(*extra_args, once = false, &callback : {{message}} -> Void)
      unless @subscriptions.has_key? {{topic}}
        @subscriptions["#{{{topic}}}"] = [] of Void*
        dispatcher =  ->(message: LibHermes::C{{message}}*, boxed_subscriptions : Void*) {
          subscriptions = Box(Hash(String, Array(Void*))).unbox(boxed_subscriptions)
          subscriptions[{{topic}}].each do |boxed_callback|
            Box({{message}} -> Void).unbox(boxed_callback).call({{message}}.new message.value)
          end
          LibHermes.{{drop}}(message)
        }
        call! LibHermes.hermes_{{ facade }}_subscribe_{{topic.id}}(@facade, *extra_args, dispatcher)
      end

      if once
        delete_callback = uninitialized -> Nil
        boxed_callback = Box.box(->(message: {{message}}) {
          callback.call(message)
          delete_callback.call()
        })
        delete_callback = -> () { @subscriptions["#{{{topic}}}"].delete(boxed_callback) }
      else
        boxed_callback = Box.box(callback)
      end

      @subscriptions["#{{{topic}}}"] << boxed_callback
      boxed_callback
    end

    # Unsubscribe to {{topic.id}} events.
    def unsubscribe_{{topic.id}}(callback_ref)
      @subscriptions[{{topic}}].delete(callback_ref)
    end
  end
end
