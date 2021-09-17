const DEFAULT_REGISTRIES = Pkg.RegistrySpec[Pkg.RegistrySpec(;
    name="General",
    uuid="23338594-aafe-5451-b93e-139f81909106",
    url="https://github.com/JuliaRegistries/General.git",
)]

"""
    main(
        env::AbstractDict=ENV,
        ci_cfg::CIService=auto_detect_ci_service(; env=env);
        entry_type::EntryType=KeepEntry(),
        registries::Vector{Pkg.RegistrySpec}=DEFAULT_REGISTRIES,
        use_existing_registries::Bool=false,
        depot::String=DEPOT_PATH[1],
        subdirs::AbstractVector{<:AbstractString}=[""],
        master_branch::Union{DefaultBranch,AbstractString}=DefaultBranch(),
        bump_compat_containing_equality_specifier=true,
        pr_title_prefix::String="",
        include_jll::Bool=false,
        unsub_from_prs=false,
        cc_user=false,
        bump_version=false,
    )

Main entry point for the package.

# Arguments
- `env::AbstractDict=ENV`: Optional dictionary of environment variables, see README for overview
- `ci_cfg::CIService=auto_detect_ci_service(; env=env)`: CI Configuration, default to what is auto-detected

# Keywords
- `entry_type::EntryType=KeepEntry()`: How to handle bumps for entry types
- `registries::Vector{Pkg.RegistrySpec}=DEFAULT_REGISTRIES`: RegistrySpec of all registries to use
- `use_existing_registries::Bool=false`: Specify whether to use the registries available at the `depot` location
- `depot::String=DEPOT_PATH[1]`: The user depot path to use
- `subdirs::AbstractVector{<:AbstractString}=[""]`: Subdirectories for nested packages
- `master_branch::Union{DefaultBranch,AbstractString}=DefaultBranch()`: Name of the master branch
- `bump_compat_containing_equality_specifier=true`: Bump compat entries with equality specifiers
- `pr_title_prefix::String=""`: Prefix for pull request titles
- `include_jll::Bool=false`: Include JLL packages to bump
- `unsub_from_prs=false`: Unsubscribe the user from the pull requests
- `cc_user=false`: CC the user on the pull requests
- `bump_version=false`: When set to true, the version in Project.toml will be bumped if a pull request is made. Minor bump if >= 1.0, or patch bump if < 1.0
"""
function main(
    env::AbstractDict=ENV,
    ci_cfg::CIService=auto_detect_ci_service(; env=env);
    entry_type::EntryType=KeepEntry(),
    registries::Vector{Pkg.RegistrySpec}=DEFAULT_REGISTRIES,
    use_existing_registries::Bool=false,
    depot::String=DEPOT_PATH[1],
    subdirs::AbstractVector{<:AbstractString}=[""],
    master_branch::Union{DefaultBranch,AbstractString}=DefaultBranch(),
    bump_compat_containing_equality_specifier=true,
    pr_title_prefix::String="",
    include_jll::Bool=false,
    unsub_from_prs=false,
    cc_user=false,
    bump_version=false,
)
    generated_prs = Vector{Union{GitHub.PullRequest,GitLab.MergeRequest}}()

    api, repo = get_api_and_repo(ci_cfg)

    for subdir in subdirs
        deps = get_project_deps(
            api,
            ci_cfg,
            repo;
            subdir=subdir,
            include_jll=include_jll,
            master_branch=master_branch,
        )

        if use_existing_registries
            get_existing_registries!(deps, depot)
        else
            get_latest_version_from_registries!(deps, registries)
        end

        for dep in deps
            pr = @mock make_pr_for_new_version(
                api,
                repo,
                dep,
                entry_type,
                ci_cfg;
                subdir=subdir,
                master_branch=master_branch,
                env=env,
                bump_compat_containing_equality_specifier=bump_compat_containing_equality_specifier,
                pr_title_prefix=pr_title_prefix,
                unsub_from_prs=unsub_from_prs,
                cc_user=cc_user,
                bump_version=bump_version,
            )

            if !isnothing(pr)
                push!(generated_prs, pr)
            end
        end
    end

    return generated_prs
end
