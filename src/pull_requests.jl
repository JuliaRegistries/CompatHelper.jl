for func in (:(==), :isequal)
    @eval function Base.$func(s1::A, s2::B; kwargs...) where {A<:GitLab.MergeRequest, B<:GitLab.MergeRequest}
        nameof(A) === nameof(B) || return false
        fields = fieldnames(A)
        fields === fieldnames(B) || return false

        for f in fields
            isdefined(s1, f) && isdefined(s2, f) || return false
            $func(getfield(s1, f), getfield(s2, f); kwargs...) || return false
        end

        return true
    end
end

function get_pull_requests(
    api::GitHub.GitHubAPI,
    repo::GitHub.Repo,
    state::String;
    per_page::Integer=100,
    page_limit::Integer=100
)
    repo_name = repo.name
    repo_owner = repo.owner.login
    paginated_prs = GitForge.paginate(
        GitHub.get_pull_requests, api, repo_owner, repo_name;
        state=state, per_page=per_page, page_limit=page_limit
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
        GitLab.get_pull_requests, api, project_id;
        state=state, per_page=per_page, page=page
    )

    return @mock unique(paginated_prs)
end
