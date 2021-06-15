function get_pull_requests(
    api::GitHub.GitHubAPI,
    repo::GitHub.Repo,
    state::String;
    per_page::Integer=100,
    page_limit::Integer=100,
)
    repo_name = repo.name
    repo_owner = repo.owner.login
    paginated_prs = GitForge.paginate(
        GitHub.get_pull_requests,
        api,
        repo_owner,
        repo_name;
        state=state,
        per_page=per_page,
        page_limit=page_limit,
    )

    return @mock unique(paginated_prs)
end

function get_pull_requests(
    api::GitLab.GitLabAPI,
    project::GitLab.Project,
    state::String;
    per_page::Integer=100,
    page::Integer=1,
)
    project_id = project.id
    paginated_prs = GitForge.paginate(
        GitLab.get_pull_requests, api, project_id; state=state, per_page=per_page, page=page
    )

    return @mock unique(paginated_prs)
end

function exclude_pull_requests_from_forks(
    repo::GitHub.Repo, pr_list::Vector{GitHub.PullRequest}
)
    return [pr for pr in pr_list if repo == pr.head.repo]
end

function exclude_pull_requests_from_forks(
    repo::GitLab.Project, pr_list::Vector{GitLab.MergeRequest}
)
    return [pr for pr in pr_list if repo.id == pr.project_id]
end

function only_my_pull_requests(username::String, pr_list::Vector{GitHub.PullRequest})
    username = lower(username)

    return [pr for pr in pr_list if lower(pr.user.login) == username]
end

function only_my_pull_requests(username::String, pr_list::Vector{GitLab.MergeRequest})
    username = lower(username)

    return [pr for pr in pr_list if lower(pr.author.username) == username]
end

function get_pr_titles(
    forge::Forge,
    repo::Union{GitHub.Repo,GitLab.Project},
    username::AbstractString,
)
    state = repo isa GitHub.Repo ? "open" : "opened"
    all_open_prs = @mock get_pull_requests(forge, repo, state)
    non_forked_prs = exclude_pull_requests_from_forks(repo, all_open_prs)
    pr_list = only_my_pull_requests(username, non_forked_prs)
    return [convert(String, strip(pr.title)) for pr in pr_list]
end
