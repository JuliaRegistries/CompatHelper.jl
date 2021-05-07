@inline function generate_compat_entry(v::VersionNumber)::String
    if v.major == 0 && v.minor == 0
        return "0.0.$(v.patch)"
    else
        return "$(v.major).$(v.minor)"
    end
end

# The `_remove_trailing_zeros` function is based on
# the `compat_version` function from:
# https://github.com/invenia/PkgTemplates.jl/blob/master/src/plugins/project_file.jl
@inline function _remove_trailing_zeros(v::VersionNumber)::String
    if v.patch == 0
        if v.minor == 0
            if v.major == 0 # v.major is 0, v.minor is 0, v.patch is 0
                throw(DomainError("0.0.0 is not a valid input"))
            else # v.major is nonzero and v.minor is 0 and v.patch is 0
                return "$(v.major)"
            end
        else # v.minor is nonzero, v.patch is 0
            return "$(v.major).$(v.minor)"
        end
    else # v.patch is nonzero
        return "$(v.major).$(v.minor).$(v.patch)"
    end
end
