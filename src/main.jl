import Pkg
import HTTP
import GitHub

const default_registries = Pkg.Types.RegistrySpec[Pkg.RegistrySpec(name = "General",
                                                                   uuid = "23338594-aafe-5451-b93e-139f81909106",
                                                                   url = "https://github.com/JuliaRegistries/General.git")]

function main(precommit_hook::Function = update_manifests,
              env::AbstractDict = ENV,
              ci_cfg::CIService = auto_detect_ci_service(; env = env);
              registries::Vector{Pkg.Types.RegistrySpec} = default_registries,
              keep_existing_compat::Bool = true,
              drop_existing_compat::Bool = false,
              master_branch::Union{DefaultBranch, AbstractString} = DefaultBranch(),
              pr_title_prefix::String = "",
              subdirs::AbstractVector{<:AbstractString} = [""],
              hostname_for_api::String="https://api.github.com",
              hostname_for_clone::String="github.com",
              use_pkg_server::Bool=false)
    if !keep_existing_compat && !drop_existing_compat
        throw(ArgumentError("At least one of keep_existing_compat, drop_existing_compat must be true"))
    end

    COMPATHELPER_PRIV_is_defined = compathelper_priv_is_defined(env)
    @info("Environment variable `COMPATHELPER_PRIV` is defined, is nonempty, and is not the string `false`: $(COMPATHELPER_PRIV_is_defined)")

    api = GitHub.GitHubWebAPI(HTTP.URI(hostname_for_api))
    clone_hostname = HostnameForClones(hostname_for_clone)
    GITHUB_TOKEN = github_token(ci_cfg; env = env)
    GITHUB_REPOSITORY = github_repository(ci_cfg; env = env)
    auth = GitHub.authenticate(api, GITHUB_TOKEN)
    repo = GitHub.repo(api, GITHUB_REPOSITORY; auth = auth)

    _all_open_prs = get_all_pull_requests(api,
                                          repo,
                                          "open";
                                          auth = auth)
    _nonforked_prs = exclude_pull_requests_from_forks(repo, _all_open_prs)
    my_username = get_my_username(ci_cfg; auth = auth, env = env)
    pr_list = only_my_pull_requests(_nonforked_prs; my_username = my_username)
    pr_titles = Vector{String}(undef, length(pr_list))
    for i = 1:length(pr_list)
        pr_titles[i] = convert(String, strip(pr_list[i].title))::String
    end

    for subdir in subdirs
        dep_to_current_compat_entry,
            dep_to_current_compat_entry_verbatim,
            dep_to_latest_version,
            deps_with_missing_compat_entry = get_project_deps(api,
                                                              clone_hostname,
                                                              repo;
                                                              auth = auth,
                                                              master_branch = master_branch,
                                                              subdir = subdir)
        get_latest_version_from_registries!(dep_to_latest_version,
                                            registries,
                                            use_pkg_server = use_pkg_server)

        make_pr_for_new_version(api,
                                clone_hostname,
                                precommit_hook,
                                repo,
                                dep_to_current_compat_entry,
                                dep_to_current_compat_entry_verbatim,
                                dep_to_latest_version,
                                deps_with_missing_compat_entry,
                                pr_list,
                                pr_titles,
                                ci_cfg;
                                auth = auth,
                                env = env,
                                keep_existing_compat = keep_existing_compat,
                                drop_existing_compat = drop_existing_compat,
                                master_branch = master_branch,
                                subdir = subdir,
                                pr_title_prefix = pr_title_prefix,
                                registries = registries)
    end
    return nothing
end
