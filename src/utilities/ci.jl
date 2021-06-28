abstract type CIService end

struct GitHubActions <: CIService
    username::String
    email::String
end

function GitHubActions()
    return GitHubActions(
        "github-actions[bot]", "41898282+github-actions[bot]@users.noreply.github.com"
    )
end

api_hostname(::GitHubActions) = "https://api.github.com"
clone_hostname(::GitHubActions) = "github.com"

github_repository(env::AbstractDict=ENV) = env["GITHUB_REPOSITORY"]
github_token(env::AbstractDict=ENV) = env["GITHUB_TOKEN"]

struct GitLabCI <: CIService
    username::String
    email::String
end

function GitLabCI()
    # TODO: Not sure what to actually put here
    return GitLabCI(
        "gitlab-ci[bot]", "gitlab-ci[bot]@gitlab.com"
    )
end

api_hostname(::GitLabCI) = "https://gitlab.com/api/v4"
clone_hostname(::GitLabCI) = "gitlab.com"

gitlab_repository(env::AbstractDict=ENV) = env["CI_PROJECT_PATH"]
gitlab_token(env::AbstractDict=ENV) = env["GITLAB_TOKEN"]

function auto_detect_ci_service(; env::AbstractDict=ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    elseif haskey(env, "GITLAB_CI")
        return GitLabCI()
    else
        throw(UnableToDetectCIService("Could not detect CI service"))
    end
end
