require "./bindings"
require "./utils"

# Contains high-level mappings to the hermes library.
module Mappings
  include Bindings
  include Utils

  private class Mapping
  end

  private class ArrayMapping
  end

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
  #
  class MqttOptions
    def initialize(
      @broker_address = "",
      @username = "",
      @password = "",
      @tls_hostname = "",
      @tls_ca_file = [] of String,
      @tls_ca_path = [] of String,
      @tls_client_key = "",
      @tls_client_cert = "",
      @tls_disable_root_store : UInt8 = 0
    )
    end

    def to_unsafe
      c_message = LibHermes::CMqttOptions.new

      c_message.broker_address = @broker_address unless @broker_address.empty?
      c_message.username = @username unless @username.empty?
      c_message.password = @password unless @password.empty?
      c_message.tls_hostname = @tls_hostname unless @tls_hostname.empty?
      tls_ca_file = StringArray.new(@tls_ca_file).to_unsafe
      c_message.tls_ca_file = pointerof(tls_ca_file)
      tls_ca_path = StringArray.new(@tls_ca_path).to_unsafe
      c_message.tls_ca_path = pointerof(tls_ca_path)
      c_message.tls_client_key = @tls_client_key unless @tls_client_key.empty?
      c_message.tls_client_cert = @tls_client_cert unless @tls_client_cert.empty?
      c_message.tls_disable_root_store = @tls_disable_root_store

      c_message
    end
  end

  # An array of strings.
  struct_array_map StringArray, String

  struct_map ActionSessionInit,
    text : String?,
    intent_filter : StringArray?,
    can_be_enqueued : Bool,
    send_intent_not_recognized : Bool

  class SessionInit < Mapping
    Utils.mapping(String | ActionSessionInit) do
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

  struct_map StartSessionMessage,
    site_id : String?,
    custom_data : String?,
    init : SessionInit

  struct_map ContinueSessionMessage,
    session_id : String,
    text : String,
    intent_filter : StringArray?,
    custom_data : String?,
    slot : String?,
    send_intent_not_recognized : Bool

  struct_map SessionQueuedMessage,
    session_id : String,
    custom_data : String?,
    site_id : String

  struct_map SessionStartedMessage,
    session_id : String,
    custom_data : String?,
    site_id : String,
    reactivated_from_session_id : String?

  struct_map SessionTermination,
    termination_type : SnipsSessionTerminationType,
    data : String?,
    component : SnipsHermesComponent

  struct_map SessionEndedMessage,
    session_id : String,
    custom_data : String?,
    termination : SessionTermination,
    site_id : String

  struct_map InstantTimeValue,
    value : String,
    grain : SnipsGrain,
    precision : SnipsPrecision

  alias InstantTimeValueData = {value: String, grain: SnipsGrain, precision: SnipsPrecision}

  struct_map TimeIntervalValue,
    from : String,
    to : String

  alias TimeIntervalValueData = {from: String, to: String}

  struct_map AmountOfMoneyValue,
    unit : String,
    value : LibC::Float,
    precision : SnipsPrecision

  alias AmountOfMoneyValueData = {unit: String, value: LibC::Float, precision: SnipsPrecision}

  struct_map TemperatureValue,
    unit : String,
    value : LibC::Float

  alias TemperatureValueData = {unit: String, value: LibC::Float}

  struct_map DurationValue,
    year : LibC::LongLong,
    quarters : LibC::LongLong,
    months : LibC::LongLong,
    weeks : LibC::LongLong,
    days : LibC::LongLong,
    hours : LibC::LongLong,
    minutes : LibC::LongLong,
    seconds : LibC::LongLong,
    precision : SnipsPrecision

  alias DurationValueData = {year: LibC::LongLong, quarters: LibC::LongLong, months: LibC::LongLong, weeks: LibC::LongLong, days: LibC::LongLong, hours: LibC::LongLong, minutes: LibC::LongLong, seconds: LibC::LongLong, precision: SnipsPrecision}

  class SlotValue < Mapping
    alias DataType = {value: DataValueType, value_type: SnipsSlotValueType}
    alias DataValueType = String |
                          LibC::Double |
                          LibC::LongLong |
                          InstantTimeValue |
                          TimeIntervalValue |
                          TemperatureValue |
                          AmountOfMoneyValue |
                          DurationValue

    Utils.mapping(DataType) do
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

  struct_array_map SlotValueArray,
    SlotValue,
    data_field: slot_values,
    size_type: Int32

  struct_map Slot,
    value : SlotValue = {ptr: true},
    alternatives : SlotValueArray = {ptr: true},
    raw_value : String,
    entity : String,
    slot_name : String,
    range_start : LibC::Int32T,
    range_end : LibC::Int32T,
    confidence_score : LibC::Float

  struct_array_map NluSlotArray,
    Slot,
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

  struct_map NluIntentClassifierResult,
    intent_name : String,
    confidence_score : LibC::Float

  struct_map NluIntentAlternative,
    intent_name : String?,
    slots : NluSlotArray? = {ptr: true},
    confidence_score : LibC::Float

  struct_array_map NluIntentAlternativeArray,
    NluIntentAlternative,
    dbl_ptr: true,
    data_field: entries,
    size_field: count

  struct_map AsrDecodingDuration,
    start : LibC::Float,
    end_ : LibC::Float

  struct_map AsrToken,
    value : String,
    confidence : LibC::Float,
    range_start : LibC::Int,
    range_end : LibC::Int,
    time : AsrDecodingDuration

  struct_array_map AsrTokenArray,
    AsrToken,
    dbl_ptr: true,
    data_field: entries,
    size_field: count

  struct_array_map AsrTokenDoubleArray,
    AsrTokenArray,
    dbl_ptr: true,
    data_field: entries,
    size_field: count

  struct_map IntentMessage,
    session_id : String,
    custom_data : String?,
    site_id : String,
    input : String,
    intent : NluIntentClassifierResult = {ptr: true},
    slots : NluSlotArray? = {ptr: true},
    alternatives : NluIntentAlternativeArray? = {ptr: true},
    asr_tokens : AsrTokenDoubleArray? = {ptr: true},
    asr_confidence : LibC::Float

  struct_map IntentNotRecognizedMessage,
    site_id : String,
    session_id : String,
    input : String,
    custom_data : String?,
    alternatives : NluIntentAlternativeArray? = {ptr: true},
    confidence_score : LibC::Float

  struct_map EndSessionMessage,
    session_id : String,
    text : String?

  struct_map MapStringToStringArrayEntry,
    key : String,
    value : StringArray

  struct_array_map MapStringToStringArray,
    MapStringToStringArrayEntry,
    data_field: entries,
    size_field: count,
    dbl_ptr: true

  struct_map InjectionRequestOperation,
    values : MapStringToStringArray = {ptr: true},
    kind : SnipsInjectionKind

  struct_array_map InjectionRequestOperations,
    InjectionRequestOperation,
    data_field: operations,
    size_field: count,
    dbl_ptr: true

  struct_map InjectionRequestMessage,
    operations : InjectionRequestOperations = {ptr: true},
    lexicon : MapStringToStringArray = {ptr: true},
    cross_language : String?,
    id : String?

  struct_map InjectionCompleteMessage,
    request_id : String

  struct_map InjectionResetRequestMessage,
    request_id : String

  struct_map InjectionResetCompleteMessage,
    request_id : String

  struct_map RegisterSoundMessage,
    sound_id : String,
    wav_sound : Array(UInt8) = {
      from_c: (
        arr = Array(UInt8).new(c_data.wav_sound_len) { |i| c_data.wav_sound[i] }
      ),
    },
    wav_sound_len : Int32

  struct_map DialogueConfigureIntent,
    intent_id : String,
    enable : Bool

  struct_array_map DialogueConfigureIntentArray,
    DialogueConfigureIntent,
    data_field: entries,
    size_field: count,
    dbl_ptr: true

  struct_map DialogueConfigureMessage,
    site_id : String,
    intents : DialogueConfigureIntentArray = {ptr: true}
end
