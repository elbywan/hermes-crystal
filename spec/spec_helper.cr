require "socket"
require "spec"
require "../src/hermes-crystal"

include Bindings
include Mappings

def find_open_port
  server = TCPServer.new("localhost", 0)
  port = server.local_address.port
  server.close
  port
end

@[Link("hermes_ffi_test", ldflags: "-L#{__DIR__}/../hermes-protocol/target/release")]
lib HermesFFITest
  fun hermes_ffi_test_round_trip_start_session(
    input : LibHermes::CStartSessionMessage*,
    output : LibHermes::CStartSessionMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_session_queued(
    input : LibHermes::CSessionQueuedMessage*,
    output : LibHermes::CSessionQueuedMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_session_started(
    input : LibHermes::CSessionStartedMessage*,
    output : LibHermes::CSessionStartedMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_session_ended(
    input : LibHermes::CSessionEndedMessage*,
    output : LibHermes::CSessionEndedMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_nlu_slot_array(
    input : LibHermes::CNluSlotArray*,
    output : LibHermes::CNluSlotArray**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_intent(
    input : LibHermes::CIntentMessage*,
    output : LibHermes::CIntentMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_intent_not_recognized(
    input : LibHermes::CIntentNotRecognizedMessage*,
    output : LibHermes::CIntentNotRecognizedMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_start_session(
    input : LibHermes::CStartSessionMessage*,
    output : LibHermes::CStartSessionMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_continue_session(
    input : LibHermes::CContinueSessionMessage*,
    output : LibHermes::CContinueSessionMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_end_session(
    input : LibHermes::CEndSessionMessage*,
    output : LibHermes::CEndSessionMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_injection_request(
    input : LibHermes::CInjectionRequestMessage*,
    output : LibHermes::CInjectionRequestMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_injection_complete(
    input : LibHermes::CInjectionCompleteMessage*,
    output : LibHermes::CInjectionCompleteMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_injection_reset_request(
    input : LibHermes::CInjectionResetRequestMessage*,
    output : LibHermes::CInjectionResetRequestMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_injection_reset_complete(
    input : LibHermes::CInjectionResetCompleteMessage*,
    output : LibHermes::CInjectionResetCompleteMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_map_string_to_string_array(
    input : LibHermes::CMapStringToStringArray*,
    output : LibHermes::CMapStringToStringArray**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_register_sound(
    input : LibHermes::CRegisterSoundMessage*,
    output : LibHermes::CRegisterSoundMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_dialogue_configure_intent(
    input : LibHermes::CDialogueConfigureIntent*,
    output : LibHermes::CDialogueConfigureIntent**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_dialogue_configure_intent_array(
    input : LibHermes::CDialogueConfigureIntentArray*,
    output : LibHermes::CDialogueConfigureIntentArray**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_dialogue_configure(
    input : LibHermes::CDialogueConfigureMessage*,
    output : LibHermes::CDialogueConfigureMessage**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_asr_token(
    input : LibHermes::CAsrToken*,
    output : LibHermes::CAsrToken**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_asr_token_array(
    input : LibHermes::CAsrTokenArray*,
    output : LibHermes::CAsrTokenArray**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_asr_token_double_array(
    input : LibHermes::CAsrTokenDoubleArray*,
    output : LibHermes::CAsrTokenDoubleArray**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_nlu_intent_alternative(
    input : LibHermes::CNluIntentAlternative*,
    output : LibHermes::CNluIntentAlternative**
  ) : SnipsResult

  fun hermes_ffi_test_round_trip_nlu_intent_alternative_array(
    input : LibHermes::CNluIntentAlternativeArray*,
    output : LibHermes::CNluIntentAlternativeArray**
  ) : SnipsResult
end
