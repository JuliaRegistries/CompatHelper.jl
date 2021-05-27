has_ssh_private_key(; env::AbstractDict=ENV) = haskey(env, PRVIATE_SSH_ENVVAR) && env[PRVIATE_SSH_ENVVAR] != "false"
lower(str::AbstractString) = lowercase(strip(str))
