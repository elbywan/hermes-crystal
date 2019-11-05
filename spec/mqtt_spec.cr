require "colorize"
require "mqtt_crystal"
require "./spec_helper"
require "./messages"

mosquitto = nil
mosquitto_port = 0
hermes = nil
client = nil

Spec.before_suite {
  puts "\n>> Mqtt test suite.".colorize.mode(:bold)
  mosquitto_port = find_open_port
  puts "> Launching mosquitto on port [#{mosquitto_port.to_s}]."
  mosquitto = Process.new(
    "mosquitto",
    ["-p", mosquitto_port.to_s], # add -v for verbose output
    # output: Process::Redirect::Inherit,
    # error: Process::Redirect::Inherit,
    output: Process::Redirect::Close,
    error: Process::Redirect::Close
  )
  puts "> Mosquitto launched.".colorize(:green)
  sleep 0.5
  begin
    puts "> Starting hermes."
    # Hermes.enable_debug_log
    hermes = Hermes.new broker_address: "localhost:#{mosquitto_port}"
    puts "> Hermes started.".colorize(:green)
    puts ""
  rescue
    mosquitto.try &.kill
    puts "!> Error while trying to setup hermes.".colorize(:red)
    raise "Error during the test setup."
  end
}

Spec.after_suite {
  puts "\n\n>> Cleanup…".colorize.mode(:bold)
  puts "> Destroying hermes instance."
  hermes.try &.destroy
  puts "> Stopping mosquitto on port [#{mosquitto_port}]."
  mosquitto.try &.kill
  puts "> Cleanup done.".colorize(:green)
}

Spec.before_each {
  client = MqttCrystal::Client.new(
    host: "localhost",
    port: mosquitto_port.to_u16
  )
}

Spec.after_each {
  client.try &.close
}

macro publish_test(name, topic, facade, message, expected, focus = false)
  it "a message of type: {{name}}."{% if focus %}, focus: true{% end %} do
    %message = {{ message }}
    %expected = {{ expected }}

    channel = Channel(String?).new
    spawn {
      begin
        _, msg = client.try(&.receive) || { nil, nil }
        channel.send msg
      rescue ex
      end
    }
    timeout = delay 1 {
      channel.send nil
    }

    client.try &.subscribe({{ topic }})
    hermes.try &.{{ facade }}.publish_{{ name }}({% if message %}(%message){% end %})

    stringified_msg = channel.receive
    timeout.cancel

    stringified_msg.try &.should eq(%expected)
    stringified_msg.should_not eq(nil)
  end
end

macro subscribe_test(name, topic, facade, class_name, subscription = nil, extra = nil, focus = false)
  it "an event of type: {{ name }}."{% if focus %}, focus: true{% end %} do
    json_msg = File.read "./spec/messages/{{name.id.camelcase}}.json"

    channel = Channel({{class_name}}?).new

    hermes.try &.{{ facade }}.subscribe_{% if subscription %}{{ subscription }}{% else %}{{ name }}{% end %}({% if extra %}*{{extra}}, {% end %}once: true) do |msg|
      channel.send msg
      Fiber.yield
    end

    spawn {
      client.try &.publish({{ topic }}, json_msg)
    }

    timeout = delay 1 {
      channel.send nil
    }

    message = channel.receive
    channel.close
    timeout.cancel

    message.try &.should eq(Messages.{{ name }})
    message.should_not eq(nil)
  end
end

describe Hermes do
  describe "should, using the high level API," do
    describe "publish" do
      publish_test(
        name: start_session,
        topic: "hermes/dialogueManager/startSession",
        facade: dialog,
        message: {
          custom_data: "custom data",
          site_id:     "default",
          init:        "notification",
        },
        expected: "{\"init\":{\"type\":\"notification\",\"text\":\"notification\"},\"customData\":\"custom data\",\"siteId\":\"default\"}",
      )

      publish_test(
        name: start_session,
        topic: "hermes/dialogueManager/startSession",
        facade: dialog,
        message: {
          custom_data: nil,
          site_id:     "default",
          init:        {
            text:                       "text",
            intent_filter:              ["one", "two", "three"],
            can_be_enqueued:            true,
            send_intent_not_recognized: true,
          },
        },
        expected: "{\"init\":{\"type\":\"action\",\"text\":\"text\",\"intentFilter\":[\"one\",\"two\",\"three\"],\"canBeEnqueued\":true,\"sendIntentNotRecognized\":true},\"customData\":null,\"siteId\":\"default\"}",
      )

      publish_test(
        name: continue_session,
        topic: "hermes/dialogueManager/continueSession",
        facade: dialog,
        message: {
          session_id:                 "677a2717-7ac8-44f8-9013-db2222f7923d",
          text:                       "text",
          intent_filter:              ["intentA", "intentB"],
          custom_data:                nil,
          slot:                       "slot",
          send_intent_not_recognized: true,
        },
        expected: "{\"sessionId\":\"677a2717-7ac8-44f8-9013-db2222f7923d\",\"text\":\"text\",\"intentFilter\":[\"intentA\",\"intentB\"],\"customData\":null,\"sendIntentNotRecognized\":true,\"slot\":\"slot\"}",
      )

      publish_test(
        name: end_session,
        topic: "hermes/dialogueManager/endSession",
        facade: dialog,
        message: {
          session_id: "session id",
          text:       "Session ended",
        },
        expected: "{\"sessionId\":\"session id\",\"text\":\"Session ended\"}",
      )

      publish_test(
        name: configure,
        topic: "hermes/dialogueManager/configure",
        facade: dialog,
        message: {
          site_id: "default",
          intents: [
            {intent_id: "intent1", enable: true},
            {intent_id: "intent2", enable: false},
            {intent_id: "intent3", enable: false},
          ],
        },
        expected: "{\"siteId\":\"default\",\"intents\":[{\"intentId\":\"intent1\",\"enable\":true},{\"intentId\":\"intent2\",\"enable\":false},{\"intentId\":\"intent3\",\"enable\":false}]}",
      )

      publish_test(
        name: injection_request,
        topic: "hermes/injection/perform",
        facade: injection,
        message: {
          id:             "abcdef",
          cross_language: "en",
          lexicon:        [
            {
              key:   "films",
              value: ["The Wolf of Wall Street", "The Lord of the Rings"],
            },
          ],
          operations: [
            {
              kind:   SnipsInjectionKind::Add,
              values: [
                {
                  key:   "films",
                  value: [
                    "The Wolf of Wall Street",
                    "The Lord of the Rings",
                  ],
                },
              ],
            },
          ],
        },
        expected: "{\"operations\":[[\"add\",{\"films\":[[\"The Wolf of Wall Street\",1],[\"The Lord of the Rings\",1]]}]],\"lexicon\":{\"films\":[\"The Wolf of Wall Street\",\"The Lord of the Rings\"]},\"crossLanguage\":\"en\",\"id\":\"abcdef\"}",
      )

      publish_test(
        name: injection_status_request,
        topic: "hermes/injection/statusRequest",
        facade: injection,
        message: nil,
        expected: "",
      )

      publish_test(
        name: toggle_on,
        topic: "hermes/feedback/sound/toggleOn",
        facade: feedback,
        message: {
          site_id:    "default",
          session_id: "id",
        },
        expected: "{\"siteId\":\"default\",\"sessionId\":\"id\"}",
      )

      publish_test(
        name: toggle_off,
        topic: "hermes/feedback/sound/toggleOff",
        facade: feedback,
        message: {
          site_id:    "default",
          session_id: "id",
        },
        expected: "{\"siteId\":\"default\",\"sessionId\":\"id\"}",
      )

      publish_test(
        name: register_sound,
        topic: "hermes/tts/registerSound/foo:bar",
        facade: tts,
        message: {
          sound_id:      "foo:bar",
          wav_sound:     [0_u8, 1_u8, 2_u8, 3_u8],
          wav_sound_len: 4,
        },
        expected: "\u0000\u0001\u0002\u0003",
      )
    end

    describe "subscribe" do
      subscribe_test(
        name: session_started,
        topic: "hermes/dialogueManager/sessionStarted",
        facade: dialog,
        class_name: SessionStartedMessage
      )
      subscribe_test(
        name: session_queued,
        topic: "hermes/dialogueManager/sessionQueued",
        facade: dialog,
        class_name: SessionQueuedMessage
      )
      subscribe_test(
        name: session_ended,
        topic: "hermes/dialogueManager/sessionEnded",
        facade: dialog,
        class_name: SessionEndedMessage
      )
      subscribe_test(
        name: intent,
        topic: "hermes/intent/jelb:lightsColor",
        facade: dialog,
        class_name: IntentMessage,
        extra: {"jelb:lightsColor"}
      )
      # Seems like hermes is keeping the same message reference for both events.
      # So we cannot reliably free it by calling drop when we have intent & intents subscribers.
      # subscribe_test(
      #   name: intent,
      #   subscription: intents,
      #   topic: "hermes/intent/jelb:lightsColor",
      #   facade: dialog,
      #   class_name: IntentMessage
      # )
      subscribe_test(
        name: intent_not_recognized,
        topic: "hermes/dialogueManager/intentNotRecognized",
        facade: dialog,
        class_name: IntentNotRecognizedMessage
      )
      subscribe_test(
        name: injection_complete,
        topic: "hermes/injection/complete",
        facade: injection,
        class_name: InjectionCompleteMessage
      )
      subscribe_test(
        name: injection_reset_complete,
        topic: "hermes/injection/reset/complete",
        facade: injection,
        class_name: InjectionResetCompleteMessage
      )
      subscribe_test(
        name: injection_status,
        topic: "hermes/injection/status",
        facade: injection,
        class_name: InjectionStatusMessage
      )
    end
  end

  robustness_iterations = 25
  describe "should, using the Flow api," do
    it "should perform one round of dialog flow at least #{robustness_iterations} times" do
      channel = Channel(String?).new

      intent_json = File.read "./spec/messages/Intent.json"
      session_ended_json = File.read "./spec/messages/SessionEnded.json"
      end_session_json = "{\"sessionId\":\"677a2717-7ac8-44f8-9013-db2222f7923d\",\"text\":\"\"}"

      flow_reference = hermes.try &.dialog.flow "jelb:lightsColor" do |msg|
        msg.should eq Messages.intent
        ""
      end

      spawn {
        counter = 0
        client.try { |client|
          client.subscribe "hermes/dialogueManager/sessionEnded"
          client.subscribe "hermes/dialogueManager/endSession"
        }
        loop do
          begin
            topic, msg = client.try(&.receive) || {nil, nil}
            sleep 0.05
            case topic
            when "hermes/dialogueManager/endSession"
              msg.should eq end_session_json
              client.try &.publish "hermes/dialogueManager/sessionEnded", session_ended_json
            when "hermes/dialogueManager/sessionEnded"
              counter += 1
              if counter >= robustness_iterations
                channel.send nil
                break
              else
                client.try &.publish("hermes/intent/jelb:lightsColor", intent_json)
              end
            else
              raise "Invalid topic received: #{topic}"
              break
            end
          rescue ex
            channel.send ex.to_s unless channel.closed?
            break
          end
        end
      }

      timeout = delay 10 {
        channel.send "Timeout…"
      }

      Fiber.yield

      client.try &.publish("hermes/intent/jelb:lightsColor", intent_json)

      result = channel.receive
      channel.close
      timeout.cancel
      flow_reference.try { |flow| hermes.try &.dialog.dispose_flows(flow) }

      if !result.nil?
        raise result
      end
    end

    it "should perform at least #{robustness_iterations} rounds of dialog flow" do
      channel = Channel(String?).new

      intent_json = File.read "./spec/messages/Intent.json"
      intent_message = Messages.intent
      session_ended_json = File.read "./spec/messages/SessionEnded.json"
      continue_session_json = "{\"sessionId\":\"677a2717-7ac8-44f8-9013-db2222f7923d\",\"text\":\"continue\",\"intentFilter\":[\"jelb:lightsColor\"],\"customData\":null,\"sendIntentNotRecognized\":false,\"slot\":\"slot\"}"
      end_session_json = "{\"sessionId\":\"677a2717-7ac8-44f8-9013-db2222f7923d\",\"text\":\"bye\"}"

      counter = 0
      loop = uninitialized Api::Flow::IntentContinuation
      loop = ->(msg : IntentMessage, flow : Api::Flow) {
        msg.should eq intent_message
        counter += 1
        if counter >= robustness_iterations
          "bye"
        else
          flow.continue "jelb:lightsColor", slot_filler: "slot", &loop
          "continue"
        end
      }
      flow_reference = hermes.try &.dialog.flow "jelb:lightsColor", &loop

      spawn {
        client.try { |client|
          client.subscribe "hermes/dialogueManager/continueSession"
          client.subscribe "hermes/dialogueManager/endSession"
        }
        loop do
          begin
            topic, msg = client.try(&.receive) || {nil, nil}
            sleep 0.05
            case topic
            when "hermes/dialogueManager/continueSession"
              msg.should eq continue_session_json
              client.try &.publish "hermes/intent/jelb:lightsColor", intent_json
            when "hermes/dialogueManager/endSession"
              msg.should eq end_session_json
              counter.should eq robustness_iterations
              client.try &.publish "hermes/dialogueManager/sessionEnded", session_ended_json
              channel.send nil
              break
            end
          rescue ex
            channel.send ex.to_s unless channel.closed?
            break
          end
        end
      }

      timeout = delay 10 {
        channel.send "Timeout…"
      }

      client.try &.publish "hermes/intent/jelb:lightsColor", intent_json

      result = channel.receive
      channel.close
      timeout.cancel
      flow_reference.try { |flow| hermes.try &.dialog.dispose_flows(flow) }

      if !result.nil?
        raise result
      end
    end

    it "should react to intents not recognized events" do
      channel = Channel(String?).new

      intent_json = File.read "./spec/messages/Intent.json"
      not_recognized_json = File.read "./spec/messages/IntentNotRecognized.json"
      session_ended_json = File.read "./spec/messages/SessionEnded.json"
      continue_session_json = "{\"sessionId\":\"677a2717-7ac8-44f8-9013-db2222f7923d\",\"text\":\"continue\",\"intentFilter\":[\"hermes/intent/jelb:lightsColor\"],\"customData\":null,\"sendIntentNotRecognized\":true,\"slot\":null}"
      end_session_json = "{\"sessionId\":\"677a2717-7ac8-44f8-9013-db2222f7923d\",\"text\":\"end\"}"

      timeout = delay 1 {
        channel.send "Timeout…"
      }

      handler = uninitialized Api::Flow::IntentContinuation
      handler = ->(_msg : IntentMessage, flow : Api::Flow) {
        flow.not_recognized {
          "end"
        }
        flow.continue "hermes/intent/jelb:lightsColor", &handler
        "continue"
      }
      flow_reference = hermes.try &.dialog.flow "jelb:lightsColor", &handler

      spawn {
        begin
          client.try { |client|
            client.subscribe "hermes/dialogueManager/continueSession"
            client.subscribe "hermes/dialogueManager/endSession"
          }
          loop do
            topic, msg = client.try(&.receive) || {nil, nil}
            case topic
            when "hermes/dialogueManager/continueSession"
              msg.should eq continue_session_json
              client.try &.publish "hermes/dialogueManager/intentNotRecognized", not_recognized_json
            when "hermes/dialogueManager/endSession"
              msg.should eq end_session_json
              client.try &.publish "hermes/dialogueManager/sessionEnded", session_ended_json
              channel.send nil
              break
            end
          end
        rescue ex
          channel.send ex.to_s unless channel.closed?
        end
      }

      client.try &.publish "hermes/intent/jelb:lightsColor", intent_json

      result = channel.receive
      channel.close
      timeout.cancel
      flow_reference.try { |flow| hermes.try &.dialog.dispose_flows(flow) }

      if !result.nil?
        raise result
      end
    end
  end
end
