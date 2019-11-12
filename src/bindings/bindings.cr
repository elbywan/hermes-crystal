require "./enums"

# Contains low level bindings to the hermes library.
#
# **This module is not meant to be used internally, as opposed to the `Mappings` module.**
module Bindings
  include Enums

  extend self

  def call!(result)
    if result == SnipsResult::Ko
      LibHermes.hermes_get_last_error(out error)
      raise String.new(error)
    end
  end

  def call!
    result = yield
    call!(result)
  end

  @[Link("hermes_mqtt_ffi", ldflags: "-L#{__DIR__}/../..")]
  lib LibHermes
    # Aliases
    alias Int32T = LibC::Int
    alias Uint64T = LibC::ULongLong
    alias Uint8T = UInt8

    # Structs

    struct CProtocolHandler
      handler : Void*
      user_data : Void*
    end

    struct CDialogueFacade
      facade : Void*
      user_data : Void*
    end

    struct CDialogueConfigureMessage
      site_id : LibC::Char*
      intents : CDialogueConfigureIntentArray*
    end

    struct CDialogueConfigureIntentArray
      entries : CDialogueConfigureIntent**
      count : LibC::Int
    end

    struct CDialogueConfigureIntent
      intent_id : LibC::Char*
      enable : UInt8
    end

    struct CContinueSessionMessage
      session_id : LibC::Char*
      text : LibC::Char*
      intent_filter : CStringArray*
      custom_data : LibC::Char*
      slot : LibC::Char*
      send_intent_not_recognized : UInt8
    end

    struct CStringArray
      data : LibC::Char**
      size : LibC::Int
    end

    struct CEndSessionMessage
      session_id : LibC::Char*
      text : LibC::Char*
    end

    struct CStartSessionMessage
      init : CSessionInit
      custom_data : LibC::Char*
      site_id : LibC::Char*
    end

    struct CSessionInit
      init_type : SnipsSessionInitType
      value : Void*
    end

    struct CActionSessionInit
      text : LibC::Char*
      intent_filter : CStringArray*
      can_be_enqueued : UInt8
      send_intent_not_recognized : UInt8
    end

    struct CIntentMessage
      session_id : LibC::Char*
      custom_data : LibC::Char*
      site_id : LibC::Char*
      input : LibC::Char*
      intent : CNluIntentClassifierResult*
      slots : CNluSlotArray*
      alternatives : CNluIntentAlternativeArray*
      asr_tokens : CAsrTokenDoubleArray*
      asr_confidence : LibC::Float
    end

    struct CNluIntentClassifierResult
      intent_name : LibC::Char*
      confidence_score : LibC::Float
    end

    struct CNluSlotArray
      entries : CNluSlot**
      count : LibC::Int
    end

    struct CNluSlot
      nlu_slot : CSlot*
    end

    struct CSlot
      value : CSlotValue*
      alternatives : CSlotValueArray*
      raw_value : LibC::Char*
      entity : LibC::Char*
      slot_name : LibC::Char*
      range_start : Int32T
      range_end : Int32T
      confidence_score : LibC::Float
    end

    struct CSlotValue
      value : Void*
      value_type : SnipsSlotValueType
    end

    struct CSlotValueArray
      slot_values : CSlotValue*
      size : Int32T
    end

    struct CNluIntentAlternativeArray
      entries : CNluIntentAlternative**
      count : LibC::Int
    end

    struct CNluIntentAlternative
      intent_name : LibC::Char*
      slots : CNluSlotArray*
      confidence_score : LibC::Float
    end

    struct CAsrTokenDoubleArray
      entries : CAsrTokenArray**
      count : LibC::Int
    end

    struct CAsrTokenArray
      entries : CAsrToken**
      count : LibC::Int
    end

    struct CAsrToken
      value : LibC::Char*
      confidence : LibC::Float
      range_start : Int32T
      range_end : Int32T
      time : CAsrDecodingDuration
    end

    struct CAsrDecodingDuration
      start : LibC::Float
      end_ : LibC::Float
    end

    struct CIntentNotRecognizedMessage
      site_id : LibC::Char*
      session_id : LibC::Char*
      input : LibC::Char*
      custom_data : LibC::Char*
      alternatives : CNluIntentAlternativeArray*
      confidence_score : LibC::Float
    end

    struct CSessionEndedMessage
      session_id : LibC::Char*
      custom_data : LibC::Char*
      termination : CSessionTermination
      site_id : LibC::Char*
    end

    struct CSessionTermination
      termination_type : SnipsSessionTerminationType
      data : LibC::Char*
      component : SnipsHermesComponent
    end

    struct CSessionQueuedMessage
      session_id : LibC::Char*
      custom_data : LibC::Char*
      site_id : LibC::Char*
    end

    struct CSessionStartedMessage
      session_id : LibC::Char*
      custom_data : LibC::Char*
      site_id : LibC::Char*
      reactivated_from_session_id : LibC::Char*
    end

    struct CErrorMessage
      session_id : LibC::Char*
      error : LibC::Char*
      context : LibC::Char*
    end

    struct CInjectionCompleteMessage
      request_id : LibC::Char*
    end

    struct CInjectionFacade
      facade : Void*
      user_data : Void*
    end

    struct CInjectionResetCompleteMessage
      request_id : LibC::Char*
    end

    struct CInjectionStatusMessage
      last_injection_date : LibC::Char*
    end

    struct CSoundFeedbackFacade
      facade : Void*
      user_data : Void*
    end

    struct CTtsFacade
      facade : Void*
      user_data : Void*
    end

    struct CVersionMessage
      major : Uint64T
      minor : Uint64T
      patch : Uint64T
    end

    struct CInjectionRequestMessage
      operations : CInjectionRequestOperations*
      lexicon : CMapStringToStringArray*
      cross_language : LibC::Char*
      id : LibC::Char*
    end

    struct CInjectionRequestOperations
      operations : CInjectionRequestOperation**
      count : LibC::Int
    end

    struct CInjectionRequestOperation
      values : CMapStringToStringArray*
      kind : SnipsInjectionKind
    end

    struct CMapStringToStringArray
      entries : CMapStringToStringArrayEntry**
      count : LibC::Int
    end

    struct CMapStringToStringArrayEntry
      key : LibC::Char*
      value : CStringArray*
    end

    struct CInjectionResetRequestMessage
      request_id : LibC::Char*
    end

    struct CMqttOptions
      broker_address : LibC::Char*
      username : LibC::Char*
      password : LibC::Char*
      tls_hostname : LibC::Char*
      tls_ca_file : CStringArray*
      tls_ca_path : CStringArray*
      tls_client_key : LibC::Char*
      tls_client_cert : LibC::Char*
      tls_disable_root_store : UInt8
    end

    struct CSiteMessage
      site_id : LibC::Char*
      session_id : LibC::Char*
    end

    struct CRegisterSoundMessage
      sound_id : LibC::Char*
      wav_sound : Uint8T*
      wav_sound_len : LibC::Int
    end

    struct CInstantTimeValue
      value : LibC::Char*
      grain : SnipsGrain
      precision : SnipsPrecision
    end

    struct CTimeIntervalValue
      from : LibC::Char*
      to : LibC::Char*
    end

    struct CAmountOfMoneyValue
      unit : LibC::Char*
      value : LibC::Float
      precision : SnipsPrecision
    end

    struct CTemperatureValue
      unit : LibC::Char*
      value : LibC::Float
    end

    struct CDurationValue
      year : Int64
      quarters : Int64
      months : Int64
      weeks : Int64
      days : Int64
      hours : Int64
      minutes : Int64
      seconds : Int64
      precision : SnipsPrecision
    end

    # Functions

    fun hermes_destroy_mqtt_protocol_handler(handler : CProtocolHandler*) : SnipsResult
    fun hermes_dialogue_publish_configure(facade : CDialogueFacade*, message : CDialogueConfigureMessage*) : SnipsResult
    fun hermes_dialogue_publish_continue_session(facade : CDialogueFacade*, message : CContinueSessionMessage*) : SnipsResult
    fun hermes_dialogue_publish_end_session(facade : CDialogueFacade*, message : CEndSessionMessage*) : SnipsResult
    fun hermes_dialogue_publish_start_session(facade : CDialogueFacade*, message : CStartSessionMessage*) : SnipsResult
    @[Raises]
    fun hermes_dialogue_subscribe_intent(facade : CDialogueFacade*, intent_name : LibC::Char*, handler : (CIntentMessage*, Void* -> Void)) : SnipsResult
    @[Raises]
    fun hermes_dialogue_subscribe_intent_not_recognized(facade : CDialogueFacade*, handler : (CIntentNotRecognizedMessage*, Void* -> Void)) : SnipsResult
    @[Raises]
    fun hermes_dialogue_subscribe_intents(facade : CDialogueFacade*, handler : (CIntentMessage*, Void* -> Void)) : SnipsResult
    @[Raises]
    fun hermes_dialogue_subscribe_session_ended(facade : CDialogueFacade*, handler : (CSessionEndedMessage*, Void* -> Void)) : SnipsResult
    @[Raises]
    fun hermes_dialogue_subscribe_session_queued(facade : CDialogueFacade*, handler : (CSessionQueuedMessage*, Void* -> Void)) : SnipsResult
    @[Raises]
    fun hermes_dialogue_subscribe_session_started(facade : CDialogueFacade*, handler : (CSessionStartedMessage*, Void* -> Void)) : SnipsResult
    fun hermes_drop_dialogue_facade(cstruct : CDialogueFacade*) : SnipsResult
    fun hermes_drop_error_message(cstruct : CErrorMessage*) : SnipsResult
    fun hermes_drop_injection_complete_message(cstruct : CInjectionCompleteMessage*) : SnipsResult
    fun hermes_drop_injection_facade(cstruct : CInjectionFacade*) : SnipsResult
    fun hermes_drop_injection_reset_complete_message(cstruct : CInjectionResetCompleteMessage*) : SnipsResult
    fun hermes_drop_injection_status_message(cstruct : CInjectionStatusMessage*) : SnipsResult
    fun hermes_drop_intent_message(cstruct : CIntentMessage*) : SnipsResult
    fun hermes_drop_intent_not_recognized_message(cstruct : CIntentNotRecognizedMessage*) : SnipsResult
    fun hermes_drop_session_ended_message(cstruct : CSessionEndedMessage*) : SnipsResult
    fun hermes_drop_session_queued_message(cstruct : CSessionQueuedMessage*) : SnipsResult
    fun hermes_drop_session_started_message(cstruct : CSessionStartedMessage*) : SnipsResult
    fun hermes_drop_sound_feedback_facade(cstruct : CSoundFeedbackFacade*) : SnipsResult
    fun hermes_drop_tts_facade(cstruct : CTtsFacade*) : SnipsResult
    fun hermes_drop_version_message(cstruct : CVersionMessage*) : SnipsResult
    fun hermes_enable_debug_logs : SnipsResult
    fun hermes_get_last_error(error : LibC::Char**) : SnipsResult
    fun hermes_injection_publish_injection_request(facade : CInjectionFacade*, message : CInjectionRequestMessage*) : SnipsResult
    fun hermes_injection_publish_injection_reset_request(facade : CInjectionFacade*, message : CInjectionResetRequestMessage*) : SnipsResult
    fun hermes_injection_publish_injection_status_request(facade : CInjectionFacade*) : SnipsResult
    @[Raises]
    fun hermes_injection_subscribe_injection_complete(facade : CInjectionFacade*, handler : (CInjectionCompleteMessage*, Void* -> Void)) : SnipsResult
    @[Raises]
    fun hermes_injection_subscribe_injection_reset_complete(facade : CInjectionFacade*, handler : (CInjectionResetCompleteMessage*, Void* -> Void)) : SnipsResult
    @[Raises]
    fun hermes_injection_subscribe_injection_status(facade : CInjectionFacade*, handler : (CInjectionStatusMessage*, Void* -> Void)) : SnipsResult
    fun hermes_protocol_handler_dialogue_facade(handler : CProtocolHandler*, facade : CDialogueFacade**) : SnipsResult
    fun hermes_protocol_handler_injection_facade(handler : CProtocolHandler*, facade : CInjectionFacade**) : SnipsResult
    fun hermes_protocol_handler_new_mqtt(handler : CProtocolHandler**, broker_address : LibC::Char*, user_data : Void*) : SnipsResult
    fun hermes_protocol_handler_new_mqtt_with_options(handler : CProtocolHandler**, mqtt_options : CMqttOptions*, user_data : Void*) : SnipsResult
    fun hermes_protocol_handler_sound_feedback_facade(handler : CProtocolHandler*, facade : CSoundFeedbackFacade**) : SnipsResult
    fun hermes_protocol_handler_tts_facade(handler : CProtocolHandler*, facade : CTtsFacade**) : SnipsResult
    fun hermes_sound_feedback_publish_toggle_off(facade : CSoundFeedbackFacade*, message : CSiteMessage*) : SnipsResult
    fun hermes_sound_feedback_publish_toggle_on(facade : CSoundFeedbackFacade*, message : CSiteMessage*) : SnipsResult
    fun hermes_tts_publish_register_sound(facade : CTtsFacade*, message : CRegisterSoundMessage*) : SnipsResult
  end
end
