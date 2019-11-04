function auto_detect_ci_service(; env=ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    else
         error("Could not detect CI service")
    end
end

function github_repository(ci_cfg::GitHubActions; env = ENV)
    result = env["GITHUB_REPOSITORY"]::String
    return result
end

function github_token(ci_cfg::GitHubActions; env = ENV)
    result = env["GITHUB_TOKEN"]::String
    return result
end
