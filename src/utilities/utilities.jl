private_compat_helper(; env::AbstractDict=ENV) = haskey(env, PRIVATE_COMPAT_HELPER) && env[PRIVATE_COMPAT_HELPER] != "false"
lower(str::AbstractString) = lowercase(strip(str))
