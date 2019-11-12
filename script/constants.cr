require "yaml"

REPO_URL       = "https://github.com/snipsco/hermes-protocol"
REPO_NAME      = "hermes-protocol"
HERMES_VERSION = File.open (Path[__DIR__] / ".." / "shard.yml").normalize do |file|
  YAML.parse(file)["hermes-version"]
end

# Ref: http://llvm.org/doxygen/classllvm_1_1Triple.html
LLVM_TRIPLE = Crystal::DESCRIPTION.split("\n")[-1].split(" ")[-1].split("-")
ARCH        = LLVM_TRIPLE[0]
VENDOR      = LLVM_TRIPLE[1]
OS          = LLVM_TRIPLE[2]
