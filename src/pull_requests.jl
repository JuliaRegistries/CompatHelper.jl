_repos_are_the_same(::GitHub.Repo, ::Nothing) = false
_repos_are_the_same(::Nothing, ::GitHub.Repo) = false
_repos_are_the_same(::Nothing, ::Nothing) = false

function get_all_pull_requests(
    api::GitHub.GitHubAPI, repo::GitHub.Repo, state::String;
    auth::GitHub.Authorization,
    per_page::Integer=100,
    page_limit::Integer=100
)
    all_pull_requests = Vector{GitHub.PullRequest}(undef, 0)

    myparams = Dict(
        "state" => state,
        "per_page" => per_page,
        "page" => 1
    )

    prs, page_data = my_retry() do
        GitHub.pull_requests(
          api, repo;
          auth, params=myparams, page_limit,
        )
    end

    append!(all_pull_requests, prs)

    while haskey(page_data, "next")
        prs, page_data = my_retry() do
            GitHub.pull_requests(
                api, repo;
                auth, page_limit, start_page=page_data["next"],
            )
        end

        append!(all_pull_requests, prs)
    end

    return unique!(all_pull_requests)
end


function _repos_are_the_same(x::GitHub.Repo, y::GitHub.Repo)
    if x.name == y.name &&
        x.full_name == y.full_name &&
        x.owner == y.owner &&
        x.id == y.id &&
        x.url == y.url &&
        x.html_url == y.html_url &&
        x.fork == y.fork

        return true
    else
        return false
    end
end

function exclude_pull_requests_from_forks(repo::GitHub.Repo, pr_list::Vector{GitHub.PullRequest})
    non_forked_pull_requests = Vector{GitHub.PullRequest}(undef, 0)

    for pr in pr_list
        always_assert(_repos_are_the_same(repo, pr.base.repo))

        if _repos_are_the_same(repo, pr.head.repo)
            push!(non_forked_pull_requests, pr)
        end
    end

    return non_forked_pull_requests
end

function only_my_pull_requests(pr_list::Vector{GitHub.PullRequest}; my_username::String)
    _my_username_lowercase = lowercase(strip(my_username))
    n = length(pr_list)
    pr_is_mine = BitVector(undef, n)

    for i = 1:n
        pr_user_login = pr_list[i].user.login

        if lowercase(strip(pr_user_login)) == _my_username_lowercase
            pr_is_mine[i] = true
        else
            pr_is_mine[i] = false
        end
    end

    return pr_list[pr_is_mine]
end

function create_new_pull_request(
    api::GitHub.GitHubAPI,
    repo::GitHub.Repo;
    base_branch::String,
    head_branch::String,
    title::String,
    body::String,
    auth::GitHub.Authorization
)
    params = Dict{String, String}(
        "title" => title,
        "head" => head_branch,
        "base" => base_branch,
        "body" => body
    )

    f = () -> GitHub.create_pull_request(
        api, repo;
        params, auth,
    )

    return my_retry(f)
end
