function github_actions_set_git_identity!()
    try
        run(`git config --global user.email '41898282+github-actions[bot]@users.noreply.github.com'`)
    catch
    end
    try
        run(`git config --global user.name 'github-actions[bot]'`)
    catch
    end
    return nothing
end

function auto_detect_ci_service(; env::AbstractDict = ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        github_actions_set_git_identity!()
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
