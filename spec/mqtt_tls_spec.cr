require "colorize"
require "./spec_helper"
require "./messages"

mosquitto = nil
mosquitto_port = 0
hermes = nil
client = nil

Spec.before_suite {
  puts "\n>> Mqtt tls test suite.".colorize.mode(:bold)
  mosquitto_port = 18886
  puts "> Launching tls mosquitto on port [#{mosquitto_port.to_s}]."
  mosquitto = Process.new(
    "mosquitto",
    ["-p", mosquitto_port.to_s, "-c", "./spec/tls/mosquitto-tls.conf", "-v"],
    # output: Process::Redirect::Inherit,
    # error: Process::Redirect::Inherit,
    output: Process::Redirect::Close,
    error: Process::Redirect::Close
  )
  puts "> Mosquitto launched.".colorize(:green)
  sleep 0.5
}

Spec.after_suite {
  puts "\n\n>> Cleanup…".colorize.mode(:bold)
  puts "> Stopping mosquitto on port [#{mosquitto_port}]."
  mosquitto.try &.kill
  puts "> Cleanup done.".colorize(:green)
}

describe Hermes do
  it "should connect to a secured mosquitto broker." do
    Hermes.new(
      broker_address: "localhost:#{mosquitto_port}",
      username: "foo",
      password: "bar",
      tls_hostname: "localhost",
      tls_ca_file: ["./spec/tls/ca.cert"],
      tls_client_key: "./spec/tls/client.key",
      tls_client_cert: "./spec/tls/client.cert",
    )
  end
end
