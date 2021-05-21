function exclude_pull_requests_from_forks(
    repo::Union{GitHub.Repo, GitLab.Project},
    pr_list::Vector{Union{GitHub.PullRequest, GitLab.MergeRequest}}
)
    return [pr for pr in pr_list if repo == pr.head.repo]
end

function only_my_pull_requests(
    username::String,
    pr_list::Vector{Union{GitHub.PullRequest, GitLab.MergeRequest}}
)
    username = lower(username)

    return [pr for pr in pr_list if lower(pr.user.login) == username]
end
