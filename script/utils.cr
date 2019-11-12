require "colorize"
require "./constants.cr"

def success(str : String)
  str.colorize.green.bold
end

def warning(str : String)
  str.colorize.yellow.bold
end

def error(str : String)
  str.colorize.red.bold
end

def bold(str : String)
  str.colorize.bold
end

def cmd!(command : String)
  system command
  unless $?.success?
    if $?.normal_exit?
      raise "Error!\n Command '#{command}' exited with error code: #{$?.exit_status}."
    elsif $?.signal_exit?
      raise "Error!\n Command '#{command}' exited due to unhandled signal: #{$?.exit_status}."
    end
  end
end

def library_file_name
  case OS
  when "macosx", "darwin"
    "libhermes_mqtt_ffi.dylib"
  when "win32"
    "hermes_mqtt_ffi.dll"
  else
    "libhermes_mqtt_ffi.so"
  end
end

def os_is_raspbian
  release_path = "/etc/os-release"
  unless File.exists? release_path
    return false
  end

  file = File.new release_path
  file.gets_to_end.includes? %(NAME="Raspbian")
end
