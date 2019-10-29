require "./spec_helper"

macro round_trip(message_name, method_suffix, message_body)
  input = {{ message_name }}.new({{ message_body }})
  c_input = input.to_unsafe
  HermesFFITest.hermes_ffi_test_round_trip_{{ method_suffix }}(pointerof(c_input), out c_output)
  output = {{ message_name }}.new(c_output.value)
  output.data.should eq(input.data)
end

describe Bindings do
  describe "should perform a round-trip on the following data structure:" do
    it "SessionQueuedMessage" do
      round_trip SessionQueuedMessage, session_queued, {
        session_id:  "session id",
        custom_data: "custom_data",
        site_id:     "default",
      }
    end

    it "SessionStartedMessage" do
      round_trip SessionStartedMessage, session_started, {
        session_id:                  "session_id",
        custom_data:                 "custom_data",
        site_id:                     "default",
        reactivated_from_session_id: "session_id_reactivated",
      }
    end

    it "SessionEndedMessage (timeout - ASR)" do
      round_trip SessionEndedMessage, session_ended, {
        session_id:  "session_id",
        custom_data: "custom_data",
        termination: {
          termination_type: SnipsSessionTerminationType::Timeout,
          data:             nil,
          component:        SnipsHermesComponent::Asr,
        },
        site_id: "site_id",
      }
    end

    it "SessionEndedMessage (error)" do
      round_trip SessionEndedMessage, session_ended, {
        session_id:  "session_id",
        custom_data: "custom_data",
        termination: {
          termination_type: SnipsSessionTerminationType::Error,
          data:             "error_message",
          component:        SnipsHermesComponent::None,
        },
        site_id: "site_id",
      }
    end

    it "NluSlotArray" do
      round_trip NluSlotArray, nlu_slot_array, [
        {
          confidence_score: 0.5_f32,
          raw_value:        "vert",
          value:            {
            value_type: SnipsSlotValueType::Custom,
            value:      "vert",
          },
          range_start:  7,
          range_end:    11,
          entity:       "Color",
          slot_name:    "Color",
          alternatives: [
            {
              value_type: SnipsSlotValueType::Custom,
              value:      "vert",
            },
            {
              value_type: SnipsSlotValueType::Number,
              value:      5.0_f64,
            },
            {
              value_type: SnipsSlotValueType::Ordinal,
              value:      10_i64,
            },
            {
              value_type: SnipsSlotValueType::Instanttime,
              value:      {
                value:     "2019-01-06 00:00:00 +01:00",
                grain:     SnipsGrain::Day,
                precision: SnipsPrecision::Exact,
              },
            },
            {
              value_type: SnipsSlotValueType::Timeinterval,
              value:      {
                from: "2019-01-06 00:00:00 +01:00",
                to:   "2019-01-07 00:01:00 +02:00",
              },
            },
            {
              value_type: SnipsSlotValueType::Amountofmoney,
              value:      {
                unit:      "EUR",
                value:     2.5_f32,
                precision: SnipsPrecision::Exact,
              },
            },
            {
              value_type: SnipsSlotValueType::Temperature,
              value:      {
                unit:  "Degrees",
                value: 25.2_f32,
              },
            },
            {
              value_type: SnipsSlotValueType::Duration,
              value:      {
                year:      1_i64,
                quarters:  2_i64,
                months:    3_i64,
                weeks:     4_i64,
                days:      5_i64,
                hours:     6_i64,
                minutes:   7_i64,
                seconds:   0_i64,
                precision: SnipsPrecision::Exact,
              },
            },
          ],
        },
      ]
    end

    it "IntentMessage" do
      round_trip IntentMessage, intent, {
        session_id:  "677a2717-7ac8-44f8-9013-db2222f7923d",
        custom_data: "customThing",
        site_id:     "default",
        input:       "moi du vert",
        intent:      {
          intent_name:      "jelb:lightsColor",
          confidence_score: 0.5_f32,
        },
        asr_confidence: 0.5_f32,
        asr_tokens:     [
          [
            {
              value:       "moi",
              confidence:  0.5_f32,
              range_start: 0,
              range_end:   3,
              time:        {
                start: 0.5_f32,
                end_:  1.0_f32,
              },
            },
            {
              value:       "du",
              confidence:  0.5_f32,
              range_start: 4,
              range_end:   6,
              time:        {
                start: 1.0_f32,
                end_:  1.5_f32,
              },
            },
            {
              value:       "vert",
              confidence:  0.5_f32,
              range_start: 7,
              range_end:   11,
              time:        {
                start: 1.5_f32,
                end_:  2.5_f32,
              },
            },
          ],
        ],
        slots: [
          {
            confidence_score: 0.5_f32,
            raw_value:        "vert",
            value:            {
              value_type: SnipsSlotValueType::Custom,
              value:      "vert",
            },
            alternatives: [
              {
                value_type: SnipsSlotValueType::Custom,
                value:      "blue",
              },
            ],
            range_start: 7,
            range_end:   11,
            entity:      "Color",
            slot_name:   "Color",
          },
        ],
        alternatives: [
          {
            intent_name:      "alternativeIntent",
            confidence_score: 0.5_f32,
            slots:            [
              {
                confidence_score: 0.5_f32,
                raw_value:        "blue",
                value:            {
                  value_type: SnipsSlotValueType::Custom,
                  value:      "blue",
                },
                alternatives: [] of SlotValue::DataType,
                range_start:  7,
                range_end:    11,
                entity:       "Color",
                slot_name:    "Color",
              },
            ],
          },
        ],
      }
    end

    it "IntentNotRecognizedMessage" do
      round_trip IntentNotRecognizedMessage, intent_not_recognized, {
        session_id:       "677a2717-7ac8-44f8-9013-db2222f7923d",
        custom_data:      "data",
        site_id:          "site id",
        input:            "Hello world",
        confidence_score: 0.5_f32,
        alternatives:     nil,
      }
    end

    it "StartSessionMessage (notification)" do
      round_trip StartSessionMessage, start_session, {
        custom_data: "custom data",
        site_id:     "default",
        init:        "notification",
      }
    end

    it "StartSessionMessage (action)" do
      round_trip StartSessionMessage, start_session, {
        custom_data: nil,
        site_id:     "default",
        init:        {
          text:                       "text",
          intent_filter:              ["one", "two", "three"],
          can_be_enqueued:            true,
          send_intent_not_recognized: true,
        },
      }
    end

    it "ContinueSessionMessage" do
      round_trip ContinueSessionMessage, continue_session, {
        session_id:                 "session id",
        text:                       "text",
        intent_filter:              ["one", "two"],
        send_intent_not_recognized: true,
        custom_data:                "custom data",
        slot:                       "slot",
      }
    end

    it "EndSessionMessage" do
      round_trip EndSessionMessage, end_session, {
        session_id: "session id",
        text:       "text",
      }
    end

    it "InjectionRequestMessage" do
      round_trip InjectionRequestMessage, injection_request, {
        id:             "identifier",
        cross_language: "en",
        lexicon:        [
          {key: "colors", value: ["red", "blue", "green"]},
        ],
        operations: [
          {
            kind:   SnipsInjectionKind::AddFromVanilla,
            values: [
              {key: "colors", value: ["red", "blue", "green"]},
            ],
          },
        ],
      }
    end

    it "InjectionCompleteMessage" do
      round_trip InjectionCompleteMessage, injection_complete, {request_id: "id"}
    end

    it "InjectionResetRequestMessage" do
      round_trip InjectionResetRequestMessage, injection_reset_request, {request_id: "id"}
    end

    it "InjectionResetCompleteMessage" do
      round_trip InjectionResetCompleteMessage, injection_reset_complete, {request_id: "id"}
    end

    it "MapStringToStringArray" do
      round_trip MapStringToStringArray, map_string_to_string_array, [
        {
          key:   "key",
          value: ["one", "two", "three"],
        },
      ]
    end

    it "RegisterSoundMessage" do
      round_trip RegisterSoundMessage, register_sound, {
        sound_id:      "sound id",
        wav_sound:     [0_u8, 1_u8, 2_u8, 3_u8],
        wav_sound_len: 4,
      }
    end

    it "DialogueConfigureIntent" do
      round_trip DialogueConfigureIntent, dialogue_configure_intent, {
        intent_id: "intent id",
        enable:    true,
      }
    end

    it "DialogueConfigureIntentArray" do
      round_trip DialogueConfigureIntentArray, dialogue_configure_intent_array, [
        {
          intent_id: "intent 1",
          enable:    false,
        },
        {
          intent_id: "intent 2",
          enable:    true,
        },
      ]
    end

    it "DialogueConfigureMessage" do
      round_trip DialogueConfigureMessage, dialogue_configure, {
        site_id: "default",
        intents: [
          {
            intent_id: "intent 1",
            enable:    false,
          },
          {
            intent_id: "intent 2",
            enable:    true,
          },
        ],
      }
    end

    it "AsrToken" do
      round_trip AsrToken, asr_token, {
        value:       "value",
        confidence:  0.5_f32,
        range_start: 2,
        range_end:   7,
        time:        {
          start: 1.2_f32,
          end_:  2.4_f32,
        },
      }
    end

    it "AsrTokenArray" do
      round_trip AsrTokenArray, asr_token_array, [{
        value:       "value",
        confidence:  0.5_f32,
        range_start: 2,
        range_end:   7,
        time:        {
          start: 1.2_f32,
          end_:  2.4_f32,
        },
      }]
    end

    it "AsrTokenDoubleArray" do
      round_trip AsrTokenDoubleArray, asr_token_double_array, [
        [
          {
            value:       "value",
            confidence:  0.5_f32,
            range_start: 2,
            range_end:   7,
            time:        {
              start: 1.2_f32,
              end_:  2.4_f32,
            },
          },
        ],
      ]
    end

    it "NluIntentAlternative" do
      round_trip NluIntentAlternative, nlu_intent_alternative, {
        intent_name: "alternative_intent",
        slots:       [
          {
            value: {
              value:      "slot_value",
              value_type: SnipsSlotValueType::Custom,
            },
            alternatives: [
              {
                value:      "alternative_slot",
                value_type: SnipsSlotValueType::Custom,
              },
            ],
            raw_value:        "value",
            entity:           "entity",
            slot_name:        "slot_name",
            range_start:      0,
            range_end:        10,
            confidence_score: 0.25_f32,
          },
        ],
        confidence_score: 0.7_f32,
      }
    end

    it "NluIntentAlternativeArray" do
      round_trip NluIntentAlternativeArray, nlu_intent_alternative_array, [{
        intent_name: "alternative_intent",
        slots:       [
          {
            value: {
              value:      "slot_value",
              value_type: SnipsSlotValueType::Custom,
            },
            alternatives: [
              {
                value:      "alternative_slot",
                value_type: SnipsSlotValueType::Custom,
              },
            ],
            raw_value:        "value",
            entity:           "entity",
            slot_name:        "slot_name",
            range_start:      0,
            range_end:        10,
            confidence_score: 0.25_f32,
          },
        ],
        confidence_score: 0.7_f32,
      }]
    end
  end
end
