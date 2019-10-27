# Contains all the enumerations related to the hermes library.
module Enums
  # The result of a call to the hermes library.
  enum SnipsResult
    # The function call returned successfully.
    Ok = 0
    # The function encountered an error, you can retrieve it using the dedicated function `hermes_get_last_error`.
    Ko = 1
  end

  # The type of sessions that can be initiated programatically.
  enum SnipsSessionInitType
    # The session expects a response from the user.
    # Users responses will be provided in the form of `CIntentMessage`s.
    Action = 1
    # The session doesn't expect a response from the user. If the session cannot be started, it
    # will be enqueued.
    Notification = 2
  end

  # The type of slot values that are supported by Snips, either custom or built in.
  enum SnipsSlotValueType
    # Custom slot type.
    Custom = 1
    # A double precision float.
    Number = 2
    # A (long long) integer.
    Ordinal = 3
    # An instant time.
    Instanttime = 4
    # An time interval.
    Timeinterval = 5
    # Some amount of money.
    Amountofmoney = 6
    # A temperature value.
    Temperature = 7
    # A duration.
    Duration = 8
    # A double precision float.
    Percentage = 9
    # Music albums.
    Musicalbum = 10
    # Music artists.
    Musicartist = 11
    # Music tracks.
    Musictrack = 12
    # Cities.
    City = 13
    # Countries.
    Country = 14
    # Regions.
    Region = 15
  end

  # The reasons that caused a session termination.
  enum SnipsSessionTerminationType
    # The session ended as expected.
    Nominal = 1
    # Dialogue was deactivated on the site the session requested.
    SiteUnavailable = 2
    # The user aborted the session.
    AbortedByUser = 3
    # The platform didn't understand was the user said.
    IntentNotRecognized = 4
    # No response was received from one of the components in a timely manner.
    Timeout = 5
    # A generic error occurred.
    Error = 6
  end

  # Describes Snips components that are part of the platform.
  enum SnipsHermesComponent
    # Not a Snips component.
    None = -1
    # The Snips audio server.
    AudioServer = 1
    # The hotword component.
    Hotword = 2
    # The automatic speech recognition.
    Asr = 3
    # The natural language understanding.
    Nlu = 4
    # The dialogue component.
    Dialogue = 5
    # The text-to-speech component.
    Tts = 6
    # The injection component.
    Injection = 7
    # The app using hermes.
    ClientApp = 8
  end

  # Type of injection supported.
  enum SnipsInjectionKind
    # Inject new data.
    Add = 1
    # Remove previously injected data before adding new data.
    AddFromVanilla = 2
  end

  # Enum representing the grain of a resolved date related value.
  enum SnipsGrain
    # The resolved value has a granularity of a year.
    Year = 0
    # The resolved value has a granularity of a quarter.
    Quarter = 1
    # The resolved value has a granularity of a mount.
    Month = 2
    # The resolved value has a granularity of a week.
    Week = 3
    # The resolved value has a granularity of a day.
    Day = 4
    # The resolved value has a granularity of an hour.
    Hour = 5
    # The resolved value has a granularity of a minute.
    Minute = 6
    # The resolved value has a granularity of a second.
    Second = 7
  end

  # Enum describing the precision of a resolved value.
  enum SnipsPrecision
    # The resolved value is approximate.
    Approximate = 0
    # The resolved value is exact.
    Exact = 1
  end
end
