require "../bindings/mappings"
require "./dialog"

# The dialog flow class can be used to easily build complex dialog trees.
struct Api::Flow
  include Mappings

  alias IntentContinuation = IntentMessage, Flow -> String?
  alias IntentNotRecognizedContinuation = IntentNotRecognizedMessage, Flow -> String?

  @dialog : Dialog
  @session_id : String
  @continuations : Hash(String, IntentContinuation)
  @not_recognized : IntentNotRecognizedContinuation?
  @slot_filler : String?
  @subscribers : {intents: Array(Pointer(Void)), not_recognized: Pointer(Void)?}

  protected def initialize(@dialog : Api::Dialog, @session_id : String)
    @continuations = Hash(String, IntentContinuation).new
    @not_recognized = nil
    @slot_filler = nil
    @subscribers = {
      intents:        [] of Pointer(Void),
      not_recognized: nil,
    }
  end

  private def cleanup
    @subscribers["intents"].each do |subscriber|
      @dialog.unsubscribe_intent(subscriber)
    end
    @subscribers["not_recognized"].try do |subscriber|
      @dialog.unsubscribe_intent_not_recognized(subscriber)
    end

    initialize(@dialog, @session_id)
  end

  protected def continue_round(msg, action)
    cleanup
    tts = action.call(msg, self)
    end_round tts
  end

  protected def end_round(text : String?)
    if @continuations.size < 1
      @dialog.publish_end_session({
        session_id: @session_id,
        text:       text,
      })
    else
      continue_session_message = {
        session_id:                 @session_id,
        intent_filter:              @continuations.keys,
        text:                       text,
        custom_data:                nil,
        slot:                       @slot_filler,
        send_intent_not_recognized: !@not_recognized.nil?,
      }
      @continuations.each do |intent_name, action|
        @subscribers["intents"] << @dialog.subscribe_intent(intent_name) do |msg|
          continue_round msg, action if msg.session_id == @session_id
        end
      end
      @not_recognized.try do |action|
        not_recognized_listener = @dialog.subscribe_intent_not_recognized do |msg|
          continue_round msg, action if msg.session_id == @session_id
        end
        @subscribers = @subscribers.merge({
          not_recognized: not_recognized_listener,
        })
      end
      @dialog.publish_continue_session(continue_session_message)
    end
  end

  # Mark an intent as a possible continuation for this round of dialog, optionally as a slot filler.
  def continue(intent_name : String, slot_filler : String? = nil, &block : IntentContinuation)
    @continuations[intent_name] = block
    @slot_filler = slot_filler if slot_filler
  end

  # Perform a custom action when no intents are recognized for this round of dialog.
  def not_recognized(&block : IntentNotRecognizedContinuation)
    @not_recognized = block
  end
end
