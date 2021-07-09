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

ci_repository(::GitHubActions, env::AbstractDict=ENV) = env["GITHUB_REPOSITORY"]
ci_token(::GitHubActions, env::AbstractDict=ENV) = env["GITHUB_TOKEN"]

function get_api_and_repo(ci::GitHubActions, hostname_for_api::AbstractString)
    token = GitHub.Token(ci_token(ci))
    api = GitHub.GitHubAPI(; token=token, url=hostname_for_api)
    repo, _ = @mock GitForge.get_repo(api, ci_repository(ci))
    return api, repo
end

struct GitLabCI <: CIService
    username::String
    email::String
end

function GitLabCI()
    # TODO: Not sure what to actually put here
    return GitLabCI("gitlab-ci[bot]", "gitlab-ci[bot]@gitlab.com")
end

api_hostname(::GitLabCI) = "https://gitlab.com/api/v4"
clone_hostname(::GitLabCI) = "gitlab.com"

ci_repository(::GitLabCI, env::AbstractDict=ENV) = env["CI_PROJECT_PATH"]
ci_token(::GitLabCI, env::AbstractDict=ENV) = env["GITLAB_TOKEN"]

function get_api_and_repo(ci::GitLabCI, hostname_for_api::AbstractString)
    token = GitLab.PersonalAccessToken(ci_token(ci))
    api = GitLab.GitLabAPI(; token=token, url=hostname_for_api)
    repo, _ = @mock GitForge.get_repo(api, ci_repository(ci))
    return api, repo
end

function get_api_and_repo(ci::Any, hostname_for_api::AbstractString)
    err = "Unknown CI Config: $(typeof(ci))"
    @error(err)
    throw(ErrorException(err))
end

function auto_detect_ci_service(; env::AbstractDict=ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    elseif haskey(env, "GITLAB_CI")
        return GitLabCI()
    else
        throw(UnableToDetectCIService("Could not detect CI service"))
    end
end
