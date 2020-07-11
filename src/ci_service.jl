function GitHubActions()
    result = GitHubActions(
        "github-actions[bot]",
        "41898282+github-actions[bot]@users.noreply.github.com",
    )
    return result
end

function TeamCity()
    result = TeamCity(
        "github-actions[bot]",
        "41898282+github-actions[bot]@users.noreply.github.com",
    )
    return result
end

function get_my_username(ci_cfg::Union{GitHubActions, TeamCity};
                         auth = nothing,
                         env::AbstractDict = ENV)
    return ci_cfg.username
end


function set_git_identity(ci_cfg::Union{GitHubActions, TeamCity})
    run(Cmd(String["git", "config", "user.name", strip(ci_cfg.username)]))
    run(Cmd(String["git", "config", "user.email", strip(ci_cfg.email)]))
    return nothing
end

function auto_detect_ci_service(; env::AbstractDict = ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    else
         error("Could not detect CI service")
    end
end

function github_repository(ci_cfg::Union{GitHubActions, TeamCity};
                           env::AbstractDict = ENV)
    result = env["GITHUB_REPOSITORY"]::String
    return result
end

function github_token(ci_cfg::Union{GitHubActions, TeamCity};
                      env::AbstractDict = ENV)
    result = env["GITHUB_TOKEN"]::String
    return result
end
