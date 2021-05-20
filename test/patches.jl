gh_unique = @patch function Base.unique(::GitForge.Paginator{GitForge.GitHub.PullRequest})
    return [GitHub.PullRequest(id=1), GitHub.PullRequest(id=2)]
end

gl_unique = @patch function Base.unique(::GitForge.Paginator{GitForge.GitLab.MergeRequest})
    return [GitLab.MergeRequest(id=1), GitLab.MergeRequest(id=2)]
end
