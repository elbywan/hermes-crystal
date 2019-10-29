require "../../src/bindings/mappings.cr"

module Messages
  include Mappings

  class_getter session_started = SessionStartedMessage.new ({
    reactivated_from_session_id: nil,
    site_id:                     "site id",
    custom_data:                 nil,
    session_id:                  "session id",
  })

  class_getter session_queued = SessionQueuedMessage.new ({
    session_id:  "Session id",
    custom_data: "Custom data",
    site_id:     "Site id",
  })

  class_getter session_ended = SessionEndedMessage.new ({
    session_id:  "677a2717-7ac8-44f8-9013-db2222f7923d",
    custom_data: nil,
    termination: {
      termination_type: SnipsSessionTerminationType::Error,
      data:             "Error message",
      component:        SnipsHermesComponent::None,
    },
    site_id: "default",
  })

  class_getter intent_not_recognized = IntentNotRecognizedMessage.new ({
    session_id:       "677a2717-7ac8-44f8-9013-db2222f7923d",
    custom_data:      "data",
    site_id:          "site id",
    input:            "Hello world",
    confidence_score: 0.5_f32,
    alternatives:     nil,
  })

  class_getter intent = IntentMessage.new ({
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
  })

  class_getter injection_status = InjectionStatusMessage.new ({
    last_injection_date: "2018-12-10T11:14:08.468+00:00",
  })

  class_getter injection_complete = InjectionCompleteMessage.new ({
    request_id: "id",
  })

  class_getter injection_reset_complete = InjectionResetCompleteMessage.new ({
    request_id: "id",
  })

  class_getter site_message = SiteMessage.new({
    site_id:    "default",
    session_id: "session id",
  })
end
