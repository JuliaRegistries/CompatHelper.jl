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
    env::AbstractDict=ENV, ci_cfg::CIService=auto_detect_ci_service(; env=env); kwargs...
)
    options = Options(; kwargs...)

    generated_prs = Vector{Union{GitHub.PullRequest,GitLab.MergeRequest}}()

    api, repo = get_api_and_repo(ci_cfg)

    for subdir in options.subdirs
        deps = get_project_deps(api, ci_cfg, repo; options, subdir)

        if options.use_existing_registries
            get_existing_registries!(deps, options.depot)
        else
            get_latest_version_from_registries!(deps, options.registries)
        end

        for dep in deps
            pr = @mock make_pr_for_new_version(
                api, repo, dep, options.entry_type, ci_cfg; options, subdir
            )

            if !isnothing(pr)
                push!(generated_prs, pr)
            end
        end
    end

    return generated_prs
end
