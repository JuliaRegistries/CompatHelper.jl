@inline function _is_raw_ssh_private_key(content::AbstractString)
    x1 = occursin("-", content)
    x2 = occursin(" ", content)
    x3 = occursin("BEGIN ", content)
    x4 = occursin("END ", content)
    x5 = occursin(" PRIVATE KEY", content)
    result = x1 && x2 && x3 && x4 && x5
    return result
end

@inline function _decode_ssh_private_key(content::AbstractString)
    if _is_raw_ssh_private_key(content)
        @info("This is a raw SSH private key.")
        return content
    end
    @info("This doesn't look like a raw SSH private key. I will assume that it is a Base64-encoded SSH private key. I will now try to Base64-decode it.")
    decoded_result_array = Base64.base64decode(content)
    decoded_result_string = String(decoded_result_array)
    @info("The Base64-decoding completed successfully.")
    if !_is_raw_ssh_private_key(decoded_result_string)
        throw(BadSSHPrivateKeyError("Private key is not in the correct format. It must be an OpenSSH private key. You should use the OpenSSH `ssh-keygen` command to generate the private key."))
    end
    @info("This was a Base64-encoded SSH private key. I Base64-decoded it, and now I have the raw SSH private key.")
    return decoded_result_string
end


@inline function compathelper_priv_is_defined(env)
    value = strip(get(env, "COMPATHELPER_PRIV", ""))
    x1 = haskey(env, "COMPATHELPER_PRIV")
    x2 = value isa AbstractString
    x3 = !isempty(value)
    x4 = value != "false"
    result = x1 && x2 && x3 && x4
    return COMPATHELPER_PRIV_is_defined
end
