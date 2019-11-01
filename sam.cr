require "sam"
require "file_utils"

library_path = "#{FileUtils.pwd}/hermes-protocol/target/debug:/usr/local/opt/openssl/lib"

# desc "Build the library"
# task "build" do
#   ENV["LIBRARY_PATH"] ||= library_path
#   system `crystal build src/main.cr -o bin/main --release`
# end

namespace "test" do
  desc "Run the roundtrip test suite"
  task "roundtrip" do
    ENV["LIBRARY_PATH"] ||= library_path
    ENV["RUST_LOG"] ||= "debug"
    system "crystal spec spec/roundtrips_spec.cr --error-trace -d"
  end

  desc "Run the mqtt test suite"
  task "mqtt" do
    ENV["LIBRARY_PATH"] ||= library_path
    ENV["RUST_LOG"] ||= "debug"
    system "crystal spec spec/mqtt_spec.cr --error-trace -d"
  end

  desc "Run the mqtt tls test suite"
  task "mqtt_tls" do
    ENV["LIBRARY_PATH"] ||= library_path
    ENV["RUST_LOG"] ||= "debug"
    system "crystal spec spec/mqtt_tls_spec.cr --error-trace -d"
  end
end

desc "Run all test suites"
task "test", ["test:roundtrip", "test:mqtt", "test:mqtt_tls"] do
end

namespace "generate" do
  desc "Generate documentation files"
  task "docs" do |_, args|
    system "rm -Rf ./docs && crystal docs"
  end

  desc "Generate bindings from a c header file"
  task "bindings" do |_, args|
    ENV["LLVM_CONFIG"] ||= args[0]?.try &.as(String) || "/usr/local/Cellar/llvm@8/8.0.1/bin/llvm-config"
    system "crystal lib/crystal_lib/src/main.cr -- gen/libsnips_hermes.cr"
  end
end

desc "Format code"
task "format" do
  system `crystal tool format`
end

desc "Format code, test and generate documentation."
task "start", ["format", "test", "generate:docs"] do
end

Sam.help
