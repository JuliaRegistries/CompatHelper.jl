import GitHub

function get_all_pull_requests(repo::GitHub.Repo,
                               state::String;
                               auth::GitHub.Authorization,
                               per_page::Integer = 100,
                               page_limit::Integer = 100)
    all_pull_requests = Vector{GitHub.PullRequest}(undef, 0)
    myparams = Dict("state" => state,
                    "per_page" => per_page,
                    "page" => 1)
    prs, page_data = GitHub.pull_requests(repo;
                                          auth=auth,
                                          params = myparams,
                                          page_limit = page_limit)
    append!(all_pull_requests, prs)
    while haskey(page_data, "next")
        prs, page_data = GitHub.pull_requests(repo;
                                              auth=auth,
                                              page_limit = page_limit,
                                              start_page = page_data["next"])
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
    my_pr_list = pr_list[pr_is_mine]
    return my_pr_list
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
