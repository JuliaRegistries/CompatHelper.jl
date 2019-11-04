import Pkg

const default_registries = Pkg.Types.RegistrySpec[Pkg.RegistrySpec(name = "General",
                                                                   uuid = "23338594-aafe-5451-b93e-139f81909106",
                                                                   url = "https://github.com/JuliaRegistries/General.git")]

function main(env::AbstractDict = ENV,
              ci_cfg::CIService = auto_detect_ci_service(; env = env);
              registries::Vector{Pkg.Types.RegistrySpec} = default_registries)
    GITHUB_TOKEN = github_token(ci_cfg; env = ENV)
    GITHUB_REPOSITORY = github_repository(ci_cfg; env = ENV)
    auth = GitHub.authenticate(env["GITHUB_TOKEN"])
    repo = GitHub.repo(env["GITHUB_REPOSITORY"]; auth = auth)
    dep_to_current_compat_entry,
        dep_to_latest_version,
        deps_with_missing_compat_entry = get_project_deps(repo; auth = auth)
    get_latest_version_from_registries!(dep_to_latest_version,
                                        default_registries)
    all_open_pull_requests = get_all_pull_requests(repo, "open"; auth = auth)
    nonforked_pull_requests = exclude_pull_requests_from_forks(repo, all_open_pull_requests)
    num_nonforked_pull_requests = length(nonforked_pull_requests)
    nonforked_pr_titles = Vector{String}(undef, num_nonforked_pull_requests)
    for i = 1:num_nonforked_pull_requests
        nonforked_pr_titles[i] = strip(nonforked_pull_requests[i].title)
    end
    make_pr_for_new_version(repo,
                            dep_to_current_compat_entry,
                            dep_to_latest_version,
                            deps_with_missing_compat_entry,
                            nonforked_pull_requests,
                            nonforked_pr_titles;
                            auth = auth)
    return nothing
end
