function has_ssh_private_key(; env::AbstractDict=ENV)
    return haskey(env, PRIVATE_SSH_ENVVAR) && env[PRIVATE_SSH_ENVVAR] != "false"
end
lower(str::AbstractString) = lowercase(strip(str))
