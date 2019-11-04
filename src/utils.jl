function get_random_string()
    return string(utc_to_string(now_localzone()), "-", rand(UInt32))::String
end
