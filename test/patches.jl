gh_unique = @patch function Base.unique(::GitForge.Paginator{GitForge.GitHub.PullRequest})
    println("here")
    return [GitHub.PullRequest(id=1), GitHub.PullRequest(id=2)]
end

gl_unique = @patch function Base.unique(::GitForge.Paginator{GitForge.GitLab.MergeRequest})
    return [GitLab.MergeRequest(id=1), GitLab.MergeRequest(id=2)]
end

project_toml = @patch function Base.joinpath(p::AbstractString...)
    return joinpath(@__DIR__, "deps", "Project.toml")
end

git_clone = @patch function CompatHelper.git_clone(url::AbstractString, p::AbstractString)
    return nothing
end
