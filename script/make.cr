require "yaml"
require "uuid"
require "file_utils"

require "./constants.cr"
require "./utils.cr"

def build_from_sources
  puts bold "> Building the hermes dynamic library from sources."
  puts warning %[/!\\ Prerequisites: git, rust and cargo.]

  tmp_dir_path = (Path[Dir.tempdir] / UUID.random.to_s).to_s
  begin
    FileUtils.mkdir tmp_dir_path

    puts bold "- Cloning hermes repository."
    FileUtils.cd tmp_dir_path do
      cmd! "git clone #{REPO_URL}"
    end

    repo_dir = (Path[tmp_dir_path] / REPO_NAME).to_s
    puts bold "Repository cloned in '#{repo_dir}'"

    FileUtils.cd repo_dir do
      puts bold "- Checkout tag #{HERMES_VERSION}."
      cmd! "git checkout tags/#{HERMES_VERSION}"

      puts bold "- Building the library."
      cmd! "cargo build -p hermes-mqtt-ffi --release"
    end

    puts bold "- Copying the generated dynamic library file to the hermes crystal folder."

    src_path = (Path[repo_dir] / "target" / "release" / library_file_name).to_s
    dest_path = (Path[__DIR__] / ".." / library_file_name).normalize.to_s
    FileUtils.cp src_path, dest_path

    if OS === "darwin" || OS === "macosx"
      # Modify the rpath
      cmd! "install_name_tool -id #{dest_path} #{dest_path}"
    end

    puts success "> Done!"
  rescue ex
    STDERR.puts ex
  ensure
    FileUtils.rm_r tmp_dir_path
  end
end
