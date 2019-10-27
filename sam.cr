require "sam"
require "file_utils"

library_path = "#{FileUtils.pwd}/hermes-protocol/target/debug"

# desc "Build the library"
# task "build" do
#   ENV["LIBRARY_PATH"] ||= library_path
#   puts `crystal build src/main.cr -o bin/main`
# end

desc "Runs the test suite"
task "test" do
  ENV["LIBRARY_PATH"] ||= library_path
  ENV["RUST_LOG"] ||= "debug"
  puts `crystal spec`
end

namespace "generate" do
  desc "Generate documentation files"
  task "docs" do |_, args|
    puts `rm -Rf ./docs && crystal docs`
  end

  desc "Generate bindings from a c header file"
  task "bindings" do |_, args|
    ENV["LLVM_CONFIG"] ||= args[0]?.try &.as(String) || "/usr/local/Cellar/llvm@8/8.0.1/bin/llvm-config"
    puts `crystal lib/crystal_lib/src/main.cr -- gen/libsnips_hermes.cr`
  end
end

desc "Test and generate documentation."
task "start", ["test", "generate:docs"] do
end

Sam.help
