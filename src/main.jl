const DEFAULT_REGISTRIES = Pkg.RegistrySpec[Pkg.RegistrySpec(;
    name="General",
    uuid="23338594-aafe-5451-b93e-139f81909106",
    url="https://github.com/JuliaRegistries/General.git",
)]

function main(
    env::AbstractDict=ENV,
    ci_cfg::CIService=auto_detect_ci_service(; env=env);
    entry_type::EntryType=KeepEntry(),
    registries::Vector{Pkg.RegistrySpec}=DEFAULT_REGISTRIES,
    subdirs::AbstractVector{<:AbstractString}=[""],
    hostname_for_api::String=api_hostname(ci_cfg),
    hostname_for_clone::String=clone_hostname(ci_cfg),
    master_branch::Union{DefaultBranch,AbstractString}=DefaultBranch(),
    bump_compat_containing_equality_specifier=true,
    pr_title_prefix::String="",
    include_jll::Bool=false,
)
    if ci_cfg isa GitHubActions
        token = GitHub.Token(github_token())
        api = GitHub.GitHubAPI(; token=token, url=hostname_for_api)
        repo, _ = @mock GitForge.get_repo(api, github_repository())
    else
        err = "Unknown CI Config"
        @error(err)
        throw(ErrorException(err))
    end

    for subdir in subdirs
        deps = @mock get_project_deps(
            api, hostname_for_clone, repo; subdir=subdir, include_jll=include_jll
        )
        @mock get_latest_version_from_registries!(deps, registries)

        for dep in deps
            @mock make_pr_for_new_version(
                api,
                hostname_for_clone,
                repo,
                dep,
                entry_type,
                ci_cfg;
                subdir=subdir,
                master_branch=master_branch,
                env=env,
                bump_compat_containing_equality_specifier=bump_compat_containing_equality_specifier,
                pr_title_prefix=pr_title_prefix,
            )
        end
    end

    return nothing
end
