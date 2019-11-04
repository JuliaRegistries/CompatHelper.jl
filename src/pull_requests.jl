import GitHub

function get_all_pull_requests(repo::GitHub.Repo,
                               state::String;
                               auth::GitHub.Authorization)
    all_pull_requests = Vector{GitHub.PullRequest}(undef, 0)
    myparams = Dict("state" => state, "per_page" => 100, "page" => 1)
    prs, page_data = GitHub.pull_requests(repo; auth=auth, params = myparams, page_limit = 100)
    append!(all_pull_requests, prs)
    while haskey(page_data, "next")
        prs, page_data = GitHub.pull_requests(repo; auth=auth, page_limit = 100, start_page = page_data["next"])
        append!(all_pull_requests, prs)
    end
    unique!(all_pull_requests)
    return all_pull_requests
end

function _repos_are_the_same(x::GitHub.Repo, y::GitHub.Repo)
    if x.name == y.name && x.full_name == y.full_name &&
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
        pr_head_repo = pr.head.repo
        if _repos_are_the_same(repo, pr_head_repo)
            push!(non_forked_pull_requests, pr)
        end
    end
    return non_forked_pull_requests
end

function create_new_pull_request(repo::GitHub.Repo;
                                 base_branch::String,
                                 head_branch::String,
                                 title::String,
                                 body::String,
                                 auth::GitHub.Authorization)
    params = Dict{String, String}()
    params["title"] = title
    params["head"] = head_branch
    params["base"] = base_branch
    params["body"] = body
    result = GitHub.create_pull_request(repo; params = params, auth = auth)
    return result
end
