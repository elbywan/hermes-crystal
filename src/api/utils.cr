module Api::Utils
  macro generate_subscriber(facade, topic, message, drop)
    def subscribe_{{topic.id}}(*extra_args, once = false, &callback : LibHermes::{{message}} -> Void)
      unless @subscriptions.has_key? {{topic}}
        @subscriptions["#{{{topic}}}"] = [] of Void*
        dispatcher =  ->(message: LibHermes::{{message}}*, boxed_subscriptions : Void*) {
          subscriptions = Box(Hash(String, Array(Void*))).unbox(boxed_subscriptions)
          subscriptions[{{topic}}].each do |boxed_callback|
            Box(LibHermes::{{message}} -> Void).unbox(boxed_callback).call(message.value)
          end
          LibHermes.{{drop}}(message)
        }
        call! LibHermes.hermes_{{ facade }}_subscribe_{{topic.id}}(@facade, *extra_args, dispatcher)
      end

      if once
        delete_callback = uninitialized -> Nil
        boxed_callback = Box.box(->(message: LibHermes::{{message}}) {
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

    def unsubscribe_{{topic.id}}(callback_ref)
      @subscriptions[{{topic}}].delete(callback_ref)
    end
  end
end
