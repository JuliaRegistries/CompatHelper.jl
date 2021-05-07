function _generate_env_dict(
    original_env::AbstractDict;
    JULIA_DEPOT_PATH
)
    result = Dict{String, String}()

    for var in ["HTTP_PROXY", "HTTPS_PROXY", "JULIA_PKG_SERVER", "PATH"]
        if haskey(original_env, var)
            result[var] = deepcopy(original_env[var])
        end
    end

    result["JULIA_DEPOT_PATH"] = deepcopy(JULIA_DEPOT_PATH)

    return result
end
