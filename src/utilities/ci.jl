abstract type CIService end

struct GitHubActions <: CIService
    username::String
    email::String
end
GitHubActions() = GitHubActions(
    "github-actions[bot]",
    "41898282+github-actions[bot]@users.noreply.github.com",
)

github_repository(env::AbstractDict = ENV) = env["GITHUB_REPOSITORY"]
github_token(env::AbstractDict = ENV) = env["GITHUB_TOKEN"]

function auto_detect_ci_service(; env::AbstractDict = ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    else
        throw(UnableToDetectCIService("Could not detect CI service"))
    end
end
