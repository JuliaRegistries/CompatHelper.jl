function has_ssh_private_key(; env::AbstractDict=ENV)
    return haskey(env, PRIVATE_SSH_ENVVAR) && env[PRIVATE_SSH_ENVVAR] != "false"
end

lower(str::AbstractString) = lowercase(strip(str))

function _max(x::Union{Nothing,Any}, y)
    if x === nothing
        return y
    else
        return max(x, y)
    end
end
