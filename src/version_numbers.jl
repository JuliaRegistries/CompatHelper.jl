function generate_compat_entry(ver::VersionNumber)
    (ver.major > 0) && return "$(ver.major)"
    (ver.minor > 0) && return "0.$(ver.minor)"
    return "0.0.$(ver.patch)"
end
