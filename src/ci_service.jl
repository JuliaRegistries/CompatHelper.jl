function GitHubActions()
    return GitHubActions("github-actions[bot]")
end

function get_my_username(ci_cfg::GitHubActions; auth = nothing, env::AbstractDict = ENV)
    return ci_cfg.username
end

function set_git_identity(ci_cfg::GitHubActions)
    run(`git config user.name 'github-actions[bot]'`)
    run(`git config user.email '41898282+github-actions[bot]@users.noreply.github.com'`)
    return nothing
end

function auto_detect_ci_service(; env::AbstractDict = ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    else
         error("Could not detect CI service")
    end
end

function github_repository(ci_cfg::GitHubActions; env::AbstractDict = ENV)
    result = env["GITHUB_REPOSITORY"]::String
    return result
end

function github_token(ci_cfg::GitHubActions; env::AbstractDict = ENV)
    result = env["GITHUB_TOKEN"]::String
    return result
end
