require "struct-mappings"
require "./bindings"

# **Contains high-level serializable mappings to the hermes library data structures.**
#
# When using publish or subscribe functions, the classes defined in this module
# will be used in place of the low level c structures.
#
# These classes are very handy since they can be initialized using plain records and arrays.
# They also implement the `to_unsafe` method and can be converted from and to c structures easily.
module Mappings
  include Bindings

  # A class representing the configuration of the MQTT client.
  #
  # - broker_address: Address of the MQTT broker in the form `ip:port`.
  # - username: Username to use to connect to the broker. Nullable.
  # - password: Password to use to connect to the broker. Nullable.
  # - tls_hostname: Hostname to use for the TLS configuration. Nullable, setting a value enables TLS.
  # - tls_ca_file: CA files to use if TLS is enabled. Nullable.
  # - tls_ca_path: CA path to use if TLS is enabled. Nullable.
  # - tls_client_key: Client key to use if TLS is enabled. Nullable.
  # - tls_client_cert: Client cert to use if TLS is enabled. Nullable.
  # - tls_disable_root_store: Boolean indicating if the root store should be disabled if TLS is enabled.
  class MqttOptions
    def initialize(
      @broker_address : String? = nil,
      @username : String? = nil,
      @password : String? = nil,
      @tls_hostname : String? = nil,
      @tls_ca_file : Array(String)? = nil,
      @tls_ca_path : Array(String)? = nil,
      @tls_client_key : String? = nil,
      @tls_client_cert : String? = nil,
      @tls_disable_root_store : UInt8 = 0
    )
    end

    def to_unsafe
      c_message = LibHermes::CMqttOptions.new

      if broker_address = @broker_address
        c_message.broker_address = broker_address
      end
      if username = @username
        c_message.username = username
      end
      if password = @password
        c_message.password = password
      end
      if tls_hostname = @tls_hostname
        c_message.tls_hostname = tls_hostname
      end
      if tls_ca_file = @tls_ca_file
        c_message.tls_ca_file = ptr_alloc(StringArray.new(tls_ca_file).to_unsafe)
      end
      if tls_ca_path = @tls_ca_path
        c_message.tls_ca_path = ptr_alloc(StringArray.new(tls_ca_path).to_unsafe)
      end
      if tls_client_key = @tls_client_key
        c_message.tls_client_key = tls_client_key
      end
      if tls_client_cert = @tls_client_cert
        c_message.tls_client_cert = tls_client_cert
      end
      c_message.tls_disable_root_store = @tls_disable_root_store

      c_message
    end
  end

  # An array of `String`.
  struct_array_mapping StringArray, String, LibHermes::CStringArray,
    from_data: elt

  # Data used to initialize a session of type "Action".
  #
  # - text [`String`] : If defined, a text to speak when the session is started.
  # - intent_filter [`StringArray`] : Nullable, an optional list of intent name to restrict the parsing of the user response to.
  # - can_be_enqueued [`Bool`] : A boolean to indicate if the session can be enqueued if it can't be started immediately.
  # - send_intent_not_recognized [`Bool`] :
  # A boolean to indicate whether the dialogue manager should handle non recognized intents by
  # itself or sent them as an `CIntentNotRecognizedMessage` for the client to handle. This
  # setting applies only to the next conversation turn.
  struct_mapping ActionSessionInit, LibHermes::CActionSessionInit,
    text : String?,
    intent_filter : StringArray? = {ptr: true},
    can_be_enqueued : Bool,
    send_intent_not_recognized : Bool

  # An class symbolizing session data that is either wrapping a `String` or an `ActionSessionInit`.
  private class SessionInit < StructMapping
    Mappings.base_mapping(String | ActionSessionInit) do
      if data.is_a?(String)
        @data = data
      else
        @data = ActionSessionInit.new(data)
      end
    end

    def initialize(c_data : LibHermes::CSessionInit)
      if c_data.init_type == SnipsSessionInitType::Notification
        @data = ptr_to_string(c_data.value).as(String)
      else
        @data = ActionSessionInit.new c_data.value.as(LibHermes::CActionSessionInit*).value
      end
    end

    def to_unsafe
      c_data = LibHermes::CSessionInit.new

      if (data = @data).is_a?(String)
        c_data.init_type = SnipsSessionInitType::Notification
        c_data.value = data.to_unsafe.as(Void*)
      else
        c_data.init_type = SnipsSessionInitType::Action
        c_data.value = ptr_alloc(data.to_unsafe).as(Void*)
      end

      c_data
    end
  end

  # A message that is used to initiate a session.
  #
  # - init [`String` | `ActionSessionInit`] : The way this session should be created.
  # - site_id [`String`] : The site where the session should be started, a nil value will be interpreted as "default".
  # - custom_data [`String`] : Optional data that will be passed to the next session event.
  struct_mapping StartSessionMessage, LibHermes::CStartSessionMessage,
    site_id : String?,
    custom_data : String?,
    init : SessionInit

  # A message used to continue a session.
  #
  # - session_id [`String`] : The id of the session this action applies to.
  # - text [`String`] : Nullable, the text to say to the user.
  # - intent_filter [`StringArray`] : Nullable, an optional list of intent name to restrict the parsing of the user response to.
  # - custom_data [`String`] : Optional data that will be passed to the next session event.
  # - slot : [`String`] :
  #  Nullable,  An optional string, requires `intent_filter` to contain a single value. If set,
  # the dialogue engine will not run the the intent classification on the user response and go
  # straight to slot filling, assuming the intent is the one passed in the `intent_filter`, and
  # searching the value of the given slot.
  # - send_intent_not_recognized [`Bool`] :
  # A boolean to indicate whether the dialogue manager should handle not recognized
  # intents by itself or sent them as a `CIntentNotRecognizedMessage` for the client to handle.
  # This setting applies only to the next conversation turn. The default value is false (and
  # the dialogue manager will handle non recognized intents by itself).
  struct_mapping ContinueSessionMessage, LibHermes::CContinueSessionMessage,
    session_id : String,
    text : String?,
    intent_filter : StringArray? = {ptr: true},
    custom_data : String?,
    slot : String?,
    send_intent_not_recognized : Bool

  # A message sent when a session is queued.
  #
  # - session_id [`String`] : The id of the session that was queued.
  # - custom_data [`String`] : Nullable, the custom data that was given at the creation of the session.
  # - site_id [`String`] : The site on which this session was queued.
  struct_mapping SessionQueuedMessage, LibHermes::CSessionQueuedMessage,
    session_id : String,
    custom_data : String?,
    site_id : String

  # A message sent when a session is started.
  #
  # - session_id [`String`] : The id of the session that was started.
  # - custom_data [`String`] : Nullable, the custom data that was given at the creation of the session.
  # - site_id [`String`] : The site on which this session was started.
  # - reactivated_from_session_id [`String`] :
  # Nullable, this field indicates this session is a reactivation of a previously ended session.
  # This is for example provided when the user continues talking to the platform without saying
  # the hotword again after a session was ended.
  struct_mapping SessionStartedMessage, LibHermes::CSessionStartedMessage,
    session_id : String,
    custom_data : String?,
    site_id : String,
    reactivated_from_session_id : String?

  # Data related to session termination.
  #
  # - termination_type [`SnipsSessionTerminationType`] : The type of the termination.
  # - data [`String`] :
  # Nullable, set if the type is `SnipsSessionTerminationType::Error` and gives more info about the error that happened.
  # - component [`SnipsHermesComponent`] :
  # If the type is `SnipsSessionTerminationType::Timeout`, this field contains the component id that generated the timeout.
  struct_mapping SessionTermination, LibHermes::CSessionTermination,
    termination_type : SnipsSessionTerminationType,
    data : String?,
    component : SnipsHermesComponent

  # A message sent when a session is ended.
  #
  # - session_id [`String`] : The id of the session that was terminated.
  # - custom_data [`String`] : Nullable, the custom data associated to this session.
  # - termination [`SessionTermination`] : How the session was ended.
  # - site_id [`String`] : The site on which this session took place.
  struct_mapping SessionEndedMessage, LibHermes::CSessionEndedMessage,
    session_id : String,
    custom_data : String?,
    termination : SessionTermination,
    site_id : String

  # An instant time slot value.
  #
  # - value [`String`] : String representation of the instant.
  # - grain [`SnipsGrain`] : The grain of the resolved instant.
  # - precision [`SnipsPrecision`] : The precision of the resolved instant.
  struct_mapping InstantTimeValue, LibHermes::CInstantTimeValue,
    value : String,
    grain : SnipsGrain,
    precision : SnipsPrecision

  private alias InstantTimeValueData = {value: String, grain: SnipsGrain, precision: SnipsPrecision}

  # A time interval slot value.
  #
  # - from [`String`] : String representation of the beginning of the interval.
  # - to [`String`] : String representation of the end of the interval.
  struct_mapping TimeIntervalValue, LibHermes::CTimeIntervalValue,
    from : String,
    to : String

  private alias TimeIntervalValueData = {from: String, to: String}

  # An amount of money slot value.
  #
  # - unit [`String`] : The currency.
  # - value [`Float32`] : The amount of money.
  # - precision [`SnipsPrecision`] : The precision of the resolved value.
  struct_mapping AmountOfMoneyValue, LibHermes::CAmountOfMoneyValue,
    unit : String,
    value : LibC::Float,
    precision : SnipsPrecision

  private alias AmountOfMoneyValueData = {unit: String, value: LibC::Float, precision: SnipsPrecision}

  # A temperature slot value.
  #
  # - unit [`String`] : The unit used.
  # - value [`Float32`] : The temperature resolved.
  struct_mapping TemperatureValue, LibHermes::CTemperatureValue,
    unit : String,
    value : LibC::Float

  private alias TemperatureValueData = {unit: String, value: LibC::Float}

  # A duration slot value.
  #
  # - year [`Int64`] : Number of years in the duration.
  # - quarters [`Int64`] : Number of quarters in the duration.
  # - months [`Int64`] : Number of months in the duration.
  # - weeks [`Int64`] : Number of weeks in the duration.
  # - days [`Int64`] : Number of days in the duration.
  # - hours [`Int64`] : Number of hours in the duration.
  # - minutes [`Int64`] : Number of minutes in the duration.
  # - seconds [`Int64`] : Number of seconds in the duration.
  # - precision [`SnipsPrecision`] : Precision of the resolved value.
  struct_mapping DurationValue, LibHermes::CDurationValue,
    year : LibC::LongLong,
    quarters : LibC::LongLong,
    months : LibC::LongLong,
    weeks : LibC::LongLong,
    days : LibC::LongLong,
    hours : LibC::LongLong,
    minutes : LibC::LongLong,
    seconds : LibC::LongLong,
    precision : SnipsPrecision

  private alias DurationValueData = {year: LibC::LongLong, quarters: LibC::LongLong, months: LibC::LongLong, weeks: LibC::LongLong, days: LibC::LongLong, hours: LibC::LongLong, minutes: LibC::LongLong, seconds: LibC::LongLong, precision: SnipsPrecision}

  # A slot value.
  #
  # - value [`DataValueType`] : The value of the slot.
  # - value_type [`SnipsSlotValueType`] : The type of the value.
  class SlotValue < StructMapping
    alias DataType = {value: DataValueType, value_type: SnipsSlotValueType}
    alias DataValueType = String |
                          LibC::Double |
                          LibC::LongLong |
                          InstantTimeValue |
                          TimeIntervalValue |
                          TemperatureValue |
                          AmountOfMoneyValue |
                          DurationValue

    def value
      @data["value"]
    end

    def value_type
      @data["value_type"]
    end

    Mappings.base_mapping(DataType) do
      value = data["value"]
      value_type = data["value_type"]

      case {value_type, value}
      when {.custom?, String},
           {.musicalbum?, String},
           {.musicartist?, String},
           {.musictrack?, String},
           {.city?, String},
           {.country?, String},
           {.region?, String},
           {.number?, LibC::Double},
           {.percentage?, LibC::Double},
           {.ordinal?, LibC::LongLong}
        @data = {
          value:      value.as(String | LibC::Double | LibC::LongLong),
          value_type: value_type,
        }
      when {.instanttime?, InstantTimeValueData}
        @data = {
          value:      InstantTimeValue.new(value),
          value_type: value_type,
        }
      when {.timeinterval?, TimeIntervalValueData}
        @data = {
          value:      TimeIntervalValue.new(value),
          value_type: value_type,
        }
      when {.temperature?, TemperatureValueData}
        @data = {
          value:      TemperatureValue.new(value),
          value_type: value_type,
        }
      when {.amountofmoney?, AmountOfMoneyValueData}
        @data = {
          value:      AmountOfMoneyValue.new(value),
          value_type: value_type,
        }
      when {.duration?, DurationValueData}
        @data = {
          value:      DurationValue.new(value),
          value_type: value_type,
        }
      else
        raise "Wrong slot value type / value combination."
      end
    end

    def initialize(c_data : LibHermes::CSlotValue)
      case value_type = c_data.value_type
      when .custom?,
           .musicalbum?,
           .musicartist?,
           .musictrack?,
           .city?,
           .country?,
           .region?
        @data = {
          value:      ptr_to_string(c_data.value),
          value_type: c_data.value_type,
        }
      when .number?,
           .percentage?
        @data = {
          value:      c_data.value.as(LibC::Double*).value,
          value_type: value_type,
        }
      when .ordinal?
        @data = {
          value:      c_data.value.as(LibC::LongLong*).value,
          value_type: value_type,
        }
      when .instanttime?
        @data = {
          value:      InstantTimeValue.new(c_data.value.as(LibHermes::CInstantTimeValue*).value),
          value_type: value_type,
        }
      when .timeinterval?
        @data = {
          value:      TimeIntervalValue.new(c_data.value.as(LibHermes::CTimeIntervalValue*).value),
          value_type: value_type,
        }
      when .amountofmoney?
        @data = {
          value:      AmountOfMoneyValue.new(c_data.value.as(LibHermes::CAmountOfMoneyValue*).value),
          value_type: value_type,
        }
      when .temperature?
        @data = {
          value:      TemperatureValue.new(c_data.value.as(LibHermes::CTemperatureValue*).value),
          value_type: value_type,
        }
      when .duration?
        @data = {
          value:      DurationValue.new(c_data.value.as(LibHermes::CDurationValue*).value),
          value_type: value_type,
        }
      else
        raise "Invalid slot value."
      end
    end

    def to_unsafe
      c_data = LibHermes::CSlotValue.new
      c_data.value_type = @data["value_type"]

      case data = @data["value"]
      when String
        c_data.value = data.to_unsafe.as(Void*)
      when LibC::Double
        ptr = Pointer.malloc(size: sizeof(LibC::Double), value: data)
        c_data.value = ptr.as(Void*)
      when LibC::LongLong
        ptr = Pointer.malloc(size: sizeof(LibC::LongLong), value: data)
        c_data.value = ptr.as(Void*)
      when InstantTimeValue
        c_data.value = ptr_alloc(data.to_unsafe).as(Void*)
      when TimeIntervalValue
        c_data.value = ptr_alloc(data.to_unsafe).as(Void*)
      when AmountOfMoneyValue
        c_data.value = ptr_alloc(data.to_unsafe).as(Void*)
      when TemperatureValue
        c_data.value = ptr_alloc(data.to_unsafe).as(Void*)
      when DurationValue
        c_data.value = ptr_alloc(data.to_unsafe).as(Void*)
      end

      c_data
    end
  end

  # An array of `SlotValue`.
  struct_array_mapping SlotValueArray,
    SlotValue,
    LibHermes::CSlotValueArray,
    data_field: slot_values
  # size_type: Int32

  # Slot data.
  #
  # - value [`SlotValue`] : The resolved value of the slot.
  # - alternatives [`SlotValueArray`] : The alternative slot values.
  # - raw_value [`String`] : The raw value as it appears in the input text.
  # - entity [`String`] : Name of the entity type of the slot.
  # - slot_name [`String`] : Name of the slot.
  # - range_start [`Int32`] : Start index of raw value in input text.
  # - range_end [`Int32`] : End index of raw value in input text.
  # - confidence_score [`Float32`] : Confidence score of the slot.
  struct_mapping Slot, LibHermes::CSlot,
    value : SlotValue = {ptr: true},
    alternatives : SlotValueArray = {ptr: true},
    raw_value : String,
    entity : String,
    slot_name : String,
    range_start : LibC::Int32T,
    range_end : LibC::Int32T,
    confidence_score : LibC::Float

  # An array of `Slot`.
  struct_array_mapping NluSlotArray,
    Slot,
    LibHermes::CNluSlotArray,
    data_field: entries,
    size_field: count,
    from_c: (
      nlu_slot = elt.value
      Slot.new nlu_slot.nlu_slot.value
    ),
    to_c: (
      slot_ptr = ptr_alloc elt.to_unsafe
      nlu_slot_ptr = ptr_alloc LibHermes::CNluSlot.new(
        nlu_slot: slot_ptr
      )
      nlu_slot_ptr
    )

  # Result of the intent classifier.
  #
  # - intent_name [`String`] : Name of the intent detected.
  # - confidence_score [`Float32`] : Confidence score, comprised between 0 and 1.
  struct_mapping NluIntentClassifierResult, LibHermes::CNluIntentClassifierResult,
    intent_name : String,
    confidence_score : LibC::Float

  # Alternative intent resolutions.
  #
  # - intent_name [`String`] : Nullable, name of the intent detected (null = no intent).
  # - slots [`NluSlotArray`] : Nullable, array of slots detected.
  # - confidence_score [`Float32`] : Confidence score.
  struct_mapping NluIntentAlternative, LibHermes::CNluIntentAlternative,
    intent_name : String?,
    slots : NluSlotArray? = {ptr: true},
    confidence_score : LibC::Float

  # Array of `NluIntentAlternative`.
  struct_array_mapping NluIntentAlternativeArray,
    NluIntentAlternative,
    LibHermes::CNluIntentAlternativeArray,
    dbl_ptr: true,
    data_field: entries,
    size_field: count

  # An ASR decoding duration.
  #
  # - start [`Float32`] : The beginning of the decoding.
  # - end [`Float32`] : The end of the decoding.
  struct_mapping AsrDecodingDuration, LibHermes::CAsrDecodingDuration,
    start : LibC::Float,
    end_ : LibC::Float

  # An ASR token.
  #
  # - value [`String`] : The text value decoded in the token.
  # - confidence [`Float32`] : The confidence score.
  # - range_start [`Int32`] : The beginning of the range in the whole text.
  # - range_end [`Int32`] : The end of the range in the whole text.
  # - time [`AsrDecodingDuration`] : The time at which the token was spoken.
  struct_mapping AsrToken, LibHermes::CAsrToken,
    value : String,
    confidence : LibC::Float,
    range_start : LibC::Int,
    range_end : LibC::Int,
    time : AsrDecodingDuration

  # An array of `AsrToken`.
  struct_array_mapping AsrTokenArray,
    AsrToken,
    LibHermes::CAsrTokenArray,
    dbl_ptr: true,
    data_field: entries,
    size_field: count

  # An array of `AsrTokenArray`.
  struct_array_mapping AsrTokenDoubleArray,
    AsrTokenArray,
    LibHermes::CAsrTokenDoubleArray,
    dbl_ptr: true,
    data_field: entries,
    size_field: count

  # A message sent on intent detection.
  #
  # - session_id [`String`] : The session identifier in which this intent was detected.
  # - custom_data [`String`] : Nullable, the custom data that was given at the session creation.
  # - site_id [`String`] : The site where the intent was detected.
  # - input [`String`] : The input that generated this intent.
  # - intent [`NluIntentClassifierResult`] : The result of the intent classification.
  # - slots [`NluSlotArray`] : Nullable, the detected slots, if any.
  # - alternatives [`NluIntentAlternativeArray`] : Nullable, alternatives intent resolutions.
  # - asr_tokens [`AsrTokenDoubleArray`] :
  # Nullable, the tokens detected by the ASR, the first array level represents the asr
  # invocation, the second one the tokens.
  # - asr_confidence [`Float32`] :
  # Confidence of the asr capture, this value is optional. Any value not in [0,1] should be ignored.
  struct_mapping IntentMessage, LibHermes::CIntentMessage,
    session_id : String,
    custom_data : String?,
    site_id : String,
    input : String,
    intent : NluIntentClassifierResult = {ptr: true},
    slots : NluSlotArray? = {ptr: true},
    alternatives : NluIntentAlternativeArray? = {ptr: true},
    asr_tokens : AsrTokenDoubleArray? = {ptr: true},
    asr_confidence : LibC::Float

  # A message sent when no intents were recognized.
  #
  # - site_id [`String`] : The site where no intent was recognized.
  # - session_id [`String`] : The session in which no intent was recognized.
  # - input [`String`] : Nullable, the text that didn't match any intent.
  # - custom_data [`String`] : Nullable, the custom data that was given at the session creation.
  # - alternatives [`NluIntentAlternativeArray`] : Nullable, alternative intent resolutions.
  # - confidence_score [`Float32`] : Expresses the confidence that no intent was found.
  struct_mapping IntentNotRecognizedMessage, LibHermes::CIntentNotRecognizedMessage,
    site_id : String,
    session_id : String,
    input : String,
    custom_data : String?,
    alternatives : NluIntentAlternativeArray? = {ptr: true},
    confidence_score : LibC::Float

  # A message that is used to terminate a session.
  #
  # - session_id [`String`] : The id of the session to end.
  # - text [`String`] : Nullable, an optional text to be told to the user before ending the session.
  struct_mapping EndSessionMessage, LibHermes::CEndSessionMessage,
    session_id : String,
    text : String?

  # A `MapStringToStringArray` entry.
  #
  # - key [`String`] : The entry key.
  # - value [`StringArray`] : The entry value.
  struct_mapping MapStringToStringArrayEntry, LibHermes::CMapStringToStringArrayEntry,
    key : String,
    value : StringArray = {ptr: true}

  # An array of `MapStringToStringArrayEntry`.
  struct_array_mapping MapStringToStringArray,
    MapStringToStringArrayEntry,
    LibHermes::CMapStringToStringArray,
    data_field: entries,
    size_field: count,
    dbl_ptr: true

  # A list of entities mapping to a list of words to inject.
  #
  # - values [`MapStringToStringArray`] : Values to inject.
  # - kind [`SnipsInjectionKind`] : The type of injection to perform.
  struct_mapping InjectionRequestOperation, LibHermes::CInjectionRequestOperation,
    values : MapStringToStringArray = {ptr: true},
    kind : SnipsInjectionKind

  # An array of `InjectionRequestOperation`.
  struct_array_mapping InjectionRequestOperations,
    InjectionRequestOperation,
    LibHermes::CInjectionRequestOperations,
    data_field: operations,
    size_field: count,
    dbl_ptr: true

  # A message used to inject values.
  #
  # - operations [`InjectionRequestOperations`] : The injection operations to perform.
  # - lexicon [`MapStringToStringArray`] : Custom pronunciations.
  # - cross_language [`String`] : Nullable, an extra language to compute the pronunciations for.
  # - id [`String`] : Id of the injection request.
  struct_mapping InjectionRequestMessage, LibHermes::CInjectionRequestMessage,
    operations : InjectionRequestOperations = {ptr: true},
    lexicon : MapStringToStringArray = {ptr: true},
    cross_language : String?,
    id : String?

  # A message sent when an injection request has completed.
  #
  # - request_id [`String`] : : Id of the injection request.
  struct_mapping InjectionCompleteMessage, LibHermes::CInjectionCompleteMessage,
    request_id : String

  # A message used to reset previously injected values.
  #
  # - request_id [`String`] : : Id of the injection request.
  struct_mapping InjectionResetRequestMessage, LibHermes::CInjectionResetRequestMessage,
    request_id : String

  # A message sent when an injection reset request has completed.
  #
  # - request_id [`String`] : : Id of the injection request.
  struct_mapping InjectionResetCompleteMessage, LibHermes::CInjectionResetCompleteMessage,
    request_id : String

  # A message sent when a status update has been requested.
  #
  # - last_injection_date [`String`] : Date at which the latest injection happened.
  struct_mapping InjectionStatusMessage, LibHermes::CInjectionStatusMessage,
    last_injection_date : String

  # A message used to register a sound and make it useable from the tts.
  #
  # - sound_id [`String`] : Sound label.
  # - wav_sound [`Array(UInt8)`] : Sound buffer (Wav PCM16).
  # - wav_sound_len [`Int32`] : Length of the sound buffer.
  struct_mapping RegisterSoundMessage, LibHermes::CRegisterSoundMessage,
    sound_id : String,
    wav_sound : Array(UInt8) = {
      from_c: (
        arr = Array(UInt8).new(c_data.wav_sound_len) { |i| c_data.wav_sound[i] }
      ),
    },
    wav_sound_len : Int32

  # Configure (enable or disable) an intent.
  #
  # - intent_id [`String`] : The name of the intent that should be configured.
  # - enable [`Bool`] : Whether this intent should be activated or not.
  struct_mapping DialogueConfigureIntent, LibHermes::CDialogueConfigureIntent,
    intent_id : String,
    enable : Bool

  # Array of `DialogueConfigureIntent`.
  struct_array_mapping DialogueConfigureIntentArray,
    DialogueConfigureIntent,
    LibHermes::CDialogueConfigureIntentArray,
    data_field: entries,
    size_field: count,
    dbl_ptr: true

  # A message used to enable or disable intent resolution.
  #
  # - site_id [`String`] :
  # Nullable, the site on which this configuration applies, if `null` the configuration will
  # be applied to all sites.
  # - intents [`DialogueConfigureIntentArray`] : An array of intents to configure.
  struct_mapping DialogueConfigureMessage, LibHermes::CDialogueConfigureMessage,
    site_id : String?,
    intents : DialogueConfigureIntentArray = {ptr: true}

  # A message used to target a site.
  #
  # - site_id [`String`] : The id of the targeted site.
  # - session_id [`String`] : Nullable, the id of the session.
  struct_mapping SiteMessage, LibHermes::CSiteMessage,
    site_id : String,
    session_id : String?
end
