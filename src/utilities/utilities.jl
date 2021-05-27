has_ssh_private_key(; env::AbstractDict=ENV) = haskey(env, PRIVATE_SSH_ENVVAR) && env[PRIVATE_SSH_ENVVAR] != "false"
lower(str::AbstractString) = lowercase(strip(str))
