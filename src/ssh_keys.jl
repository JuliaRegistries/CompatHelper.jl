import Base64

@inline function _is_raw_ssh_private_key(content::AbstractString)
    result = ( occursin("-", content) ) && ( occursin(" ", content) ) &&
                                           ( occursin("BEGIN ", content) ) &&
                                           ( occursin("END ", content) ) &&
                                           ( occursin(" PRIVATE KEY", content) )

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
    COMPATHELPER_PRIV_is_defined = ( haskey(env, "COMPATHELPER_PRIV") ) && ( isa(env["COMPATHELPER_PRIV"], AbstractString) ) &&
                                                                           ( length(strip(env["COMPATHELPER_PRIV"])) > 0 ) &&
                                                                           ( !occursin("false", strip(env["COMPATHELPER_PRIV"])) )
    return COMPATHELPER_PRIV_is_defined
end
