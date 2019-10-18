require "sam"
require "file_utils"

desc "Runs the test suite"
task "test" do
  ENV["LIBRARY_PATH"] ||= "#{FileUtils.pwd}/hermes-protocol/target/debug"
  ENV["RUST_LOG"] ||= "debug"
  puts `crystal spec`
end

desc "Generate bindings from a c header file"
task "bindings" do |_, args|
  ENV["LLVM_CONFIG"] ||= args[0]?.try &.as(String) || "/usr/local/Cellar/llvm@8/8.0.1/bin/llvm-config"
  puts `crystal lib/crystal_lib/src/main.cr -- gen/libsnips_hermes.cr`
end

Sam.help
