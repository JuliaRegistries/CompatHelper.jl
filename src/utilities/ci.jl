abstract type CIService end

struct GitHubActions <: CIService
    username::String
    email::String
end
GitHubActions() = GitHubActions("github-actions[bot]", "41898282+github-actions[bot]@users.noreply.github.com")

github_repository(env::AbstractDict=ENV) = env["GITHUB_REPOSITORY"]
github_token(env::AbstractDict=ENV) = env["GITHUB_TOKEN"]

function set_git_identity(ci_cfg::GitHubActions)
    run(Cmd(String["git", "config", "user.name", strip(ci_cfg.username)]))
    run(Cmd(String["git", "config", "user.email", strip(ci_cfg.email)]))

    return nothing
end

function auto_detect_ci_service(; env::AbstractDict=ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    else
        throw(UnableToDetectCIService("Could not detect CI service"))
    end
end
