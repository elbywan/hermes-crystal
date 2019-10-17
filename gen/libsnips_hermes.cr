@[Include(
  "libsnips_hermes.h",
  flags: "-I./gen"
)]
@[Link("hermes_mqtt_ffi")]
lib LibHermes
  fun hermes_destroy_mqtt_protocol_handler
  fun hermes_dialogue_publish_configure
  fun hermes_dialogue_publish_continue_session
  fun hermes_dialogue_publish_end_session
  fun hermes_dialogue_publish_start_session
  fun hermes_dialogue_subscribe_intent
  fun hermes_dialogue_subscribe_intent_not_recognized
  fun hermes_dialogue_subscribe_intents
  fun hermes_dialogue_subscribe_session_ended
  fun hermes_dialogue_subscribe_session_queued
  fun hermes_dialogue_subscribe_session_started
  fun hermes_drop_dialogue_facade
  fun hermes_drop_error_message
  fun hermes_drop_injection_complete_message
  fun hermes_drop_injection_facade
  fun hermes_drop_injection_reset_complete_message
  fun hermes_drop_injection_status_message
  fun hermes_drop_intent_message
  fun hermes_drop_intent_not_recognized_message
  fun hermes_drop_session_ended_message
  fun hermes_drop_session_queued_message
  fun hermes_drop_session_started_message
  fun hermes_drop_sound_feedback_facade
  fun hermes_drop_tts_facade
  fun hermes_drop_version_message
  fun hermes_enable_debug_logs
  fun hermes_get_last_error
  fun hermes_injection_publish_injection_request
  fun hermes_injection_publish_injection_reset_request
  fun hermes_injection_publish_injection_status_request
  fun hermes_injection_subscribe_injection_complete
  fun hermes_injection_subscribe_injection_reset_complete
  fun hermes_injection_subscribe_injection_status
  fun hermes_protocol_handler_dialogue_facade
  fun hermes_protocol_handler_injection_facade
  fun hermes_protocol_handler_new_mqtt
  fun hermes_protocol_handler_new_mqtt_with_options
  fun hermes_protocol_handler_sound_feedback_facade
  fun hermes_protocol_handler_tts_facade
  fun hermes_sound_feedback_publish_toggle_off
  fun hermes_sound_feedback_publish_toggle_on
  fun hermes_tts_publish_register_sound
end
