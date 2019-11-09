import Pkg

const default_registries = Pkg.Types.RegistrySpec[Pkg.RegistrySpec(name = "General",
                                                                   uuid = "23338594-aafe-5451-b93e-139f81909106",
                                                                   url = "https://github.com/JuliaRegistries/General.git")]

const default_value_for_keep_existing_compat = true
const default_value_for_drop_existing_compat = false

function main(precommit_hook::Function = () -> (),
              env::AbstractDict = ENV,
              ci_cfg::CIService = auto_detect_ci_service(; env = env);
              registries::Vector{Pkg.Types.RegistrySpec} = default_registries,
              keep_existing_compat::Bool = default_value_for_keep_existing_compat,
              drop_existing_compat::Bool = default_value_for_drop_existing_compat,
              master_branch::Union{DefaultBranch, AbstractString} = DefaultBranch(),
              pr_title_prefix::String = "")
    if !keep_existing_compat && !drop_existing_compat
        throw(ArgumentError("At least one of keep_existing_compat, drop_existing_compat must be true"))
    end
    GITHUB_TOKEN = github_token(ci_cfg; env = ENV)
    GITHUB_REPOSITORY = github_repository(ci_cfg; env = ENV)
    auth = GitHub.authenticate(env["GITHUB_TOKEN"])
    repo = GitHub.repo(env["GITHUB_REPOSITORY"]; auth = auth)
    dep_to_current_compat_entry,
        dep_to_current_compat_entry_verbatim,
        dep_to_latest_version,
        deps_with_missing_compat_entry = get_project_deps(repo;
                                                          auth = auth,
                                                          master_branch = master_branch)
    get_latest_version_from_registries!(dep_to_latest_version,
                                        default_registries)
    _all_open_prs = get_all_pull_requests(repo, "open"; auth = auth)
    _nonforked_prs = exclude_pull_requests_from_forks(repo, _all_open_prs)
    my_username = get_my_username(ci_cfg; auth = auth, env = env)
    pr_list = only_my_pull_requests(_nonforked_prs; my_username = my_username)
    pr_titles = Vector{String}(undef, length(pr_list))
    for i = 1:length(pr_list)
        pr_titles[i] = convert(String, strip(pr_list[i].title))::String
    end
    make_pr_for_new_version(precommit_hook,
                            repo,
                            dep_to_current_compat_entry,
                            dep_to_current_compat_entry_verbatim,
                            dep_to_latest_version,
                            deps_with_missing_compat_entry,
                            pr_list,
                            pr_titles,
                            ci_cfg;
                            auth = auth,
                            keep_existing_compat = keep_existing_compat,
                            drop_existing_compat = drop_existing_compat,
                            master_branch = master_branch,
                            pr_title_prefix = pr_title_prefix)
    return nothing
end
