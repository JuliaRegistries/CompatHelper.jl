function _generate_env_dict(original_env::AbstractDict;
                            JULIA_DEPOT_PATH)
    result = Dict{String, String}()
    if haskey(original_env, "HTTP_PROXY")
        result["HTTP_PROXY"] = deepcopy(original_env["HTTP_PROXY"])
    end
    if haskey(original_env, "HTTPS_PROXY")
        result["HTTPS_PROXY"] = deepcopy(original_env["HTTPS_PROXY"])
    end
    if haskey(original_env, "JULIA_PKG_SERVER")
        result["JULIA_PKG_SERVER"] = deepcopy(original_env["JULIA_PKG_SERVER"])
    end
    result["PATH"] = deepcopy(original_env["PATH"])
    result["JULIA_DEPOT_PATH"] = deepcopy(JULIA_DEPOT_PATH)
    return result
end
