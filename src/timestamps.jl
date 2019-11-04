import Dates
import Printf
import TimeZones

@inline now_localzone() = TimeZones.now(TimeZones.localzone())

function utc_to_string(zdt::TimeZones.ZonedDateTime)
    zdt_as_utc = TimeZones.astimezone(zdt, TimeZones.tz"UTC")
    year = Dates.Year(zdt_as_utc.utc_datetime).value
    month = Dates.Month(zdt_as_utc.utc_datetime).value
    day = Dates.Day(zdt_as_utc.utc_datetime).value
    hour = Dates.Hour(zdt_as_utc.utc_datetime).value
    minute = Dates.Minute(zdt_as_utc.utc_datetime).value
    second = Dates.Second(zdt_as_utc.utc_datetime).value
    millisecond = Dates.Millisecond(zdt_as_utc.utc_datetime).value
    result = Printf.@sprintf "%04d-%02d-%02d-%02d-%02d-%02d-%03d" year month day hour minute second millisecond
    return result
end
