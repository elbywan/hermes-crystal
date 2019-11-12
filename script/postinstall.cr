require "http/client"

require "./utils.cr"
require "./constants.cr"
require "./make.cr"

SUPPORTED_CONFIGURATIONS = {
  {"linux", "arm"}     => "linux-raspbian-armhf",
  {"linux", "x86_64"}  => "linux-debian-x86_64",
  {"darwin", "x86_64"} => "macos-darwin-x86_64",
  {"macosx", "x86_64"} => "macos-darwin-x86_64",
}

puts bold "- Checking platform support."

if SUPPORTED_CONFIGURATIONS.has_key?({OS, ARCH})
  begin
    dest_path = (Path[__DIR__] / ".." / library_file_name).normalize.to_s
    puts bold "- Downloading the hermes mqtt dynamic library file. Target: #{dest_path}."

    target_triple = SUPPORTED_CONFIGURATIONS[{OS, ARCH}]
    file_url = "http://s3.amazonaws.com/snips/hermes-mqtt/#{HERMES_VERSION}/#{target_triple}/#{library_file_name}"

    HTTP::Client.get file_url do |response|
      if response.status_code >= 400
        raise "Error while downloading the file. Status code: #{response.status_code}. Message: #{response.status_message}"
      end

      body_io = response.body_io
      slice = Bytes.new(16384)
      total_size = response.headers["content_length"].to_i
      size_downloaded = 0
      File.open dest_path, mode: "w" do |file|
        loop do
          nb_read = body_io.read slice
          size_downloaded += nb_read / 1000
          # puts "\u001b[1000D" + str(i + 1) + "%"
          print "\e[1000DDownloaded: #{(size_downloaded).round(3)} / #{total_size / 1000} KB."
          break if nb_read == 0
          file.write slice[...nb_read]
        end
      end
      print "\n"
    end

    if OS === "darwin" || OS === "macosx"
      # Modify the rpath
      cmd! "install_name_tool -id #{dest_path} #{dest_path}"
    end

    puts success "> Done!"
  rescue ex
    puts error "Unexpected error: #{ex}."
  end
else
  puts error "!> This os and architecture combination is not supported: #{{OS, ARCH}}"
  build_from_sources
end
