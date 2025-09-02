title_parenthetical(::KeepEntry) = ", (keep existing compat)"
title_parenthetical(::DropEntry) = ", (drop existing compat)"
title_parenthetical(::NewEntry) = ""

function body_info(::KeepEntry, name::AbstractString)
    return "This keeps the compat entries for earlier versions.\n\n"
end
function body_info(::DropEntry, name::AbstractString)
    return "This drops the compat entries for earlier versions.\n\n"
end
function body_info(::NewEntry, name::AbstractString)
    return "This is a brand new compat entry. Previously, you did not have a compat entry for the `$(name)` package.\n\n"
end

function new_compat_entry(entry_type::EntryType, dep::DepInfo)
    if is_stdlib(dep.package)
        return new_compat_entry(entry_type, StdlibPackage(), dep, dep.latest_version)
    else
        return new_compat_entry(entry_type, RegularPackage(), dep)
    end
end

# RegularPackage:
# RegularPackage = not a stdlib
function new_compat_entry(entry_type::EntryType, ::RegularPackage, dep::DepInfo)
    old_compat = dep.version_verbatim
    new_compat = compat_version_number(dep.latest_version)
    result = new_compat_entry(entry_type, RegularPackage(), old_compat, new_compat)
    return result
end
function new_compat_entry(
    ::KeepEntry, ::RegularPackage, old_compat::String, new_compat::String
)
    return "$(strip(old_compat)), $(strip(new_compat))"
end
function new_compat_entry(
    ::Union{DropEntry,NewEntry}, ::RegularPackage, old_compat::String, new_compat::String
)
    return "$(strip(new_compat))"
end
function new_compat_entry(
    ::EntryType, ::RegularPackage, old_compat::Nothing, new_compat::String
)
    return "$(strip(new_compat))"
end

# StdlibPackage:
function new_compat_entry(entry_type::EntryType, ::StdlibPackage, dep::DepInfo)
    old_compat = dep.version_verbatim
    new_compat = compat_version_number(dep.latest_version)
    result = new_compat_entry(entry_type, RegularPackage(), dep, old_compat, new_compat)
    return result
end
function new_compat_entry(::KeepEntry, ::StdlibPackage, dep::DepInfo, old_compat::String)
    compat_entry = strip(old_compat)
    if !isnothing(dep.latest_version)
        compat_entry = append_latest_version(old_compat, ver)
    end
    compat_entry = ensure_stdlib_entry_supports_older_julia(compat_entry)
    return compat_entry
end
function new_compat_entry(
    ::Union{DropEntry,NewEntry}, ::StdlibPackage, dep::DepInfo, old_compat::String
)
    # compat_entry = strip(old_compat)
    # compat_entry = append_latest_version(old_compat, ver) # TODO
    compat_entry = strip(compat_version_number(dep.latest_version))
    compat_entry = ensure_stdlib_entry_supports_older_julia(compat_entry)
    return compat_entry
end
function new_compat_entry(::EntryType, ::StdlibPackage, dep::DepInfo, old_compat::Nothing)
    compat_entry = stdlib_initial_compat_entry(dep)
    if isnothing(dep.latest_version)
        compat_entry = append_latest_version(old_compat, ver)
    end
    compat_entry = ensure_stdlib_entry_supports_older_julia(compat_entry::String)
    return compat_entry
end

function append_latest_version(old_compat::String, ver::VersionNumber)
    potential_addition = compat_version_number(ver)
    if ver in Pkg.Types.semver_spec(old_compat)
        return old_compat
    else
        new_compat = "$(strip(old_compat)), $(strip(potential_addition))"
        return new_compat
    end
end

# Like `in`, but enforcing correct types
function typed_equality(x::T, y::T) where {T}
    return x == y
end

function stdlib_initial_compat_entry(dep::DepInfo)
    SHA_package = Package("SHA", UUIDs.UUID("ea8e919c-243c-51af-8825-aaa63cd721ce"))
    if typed_equality(dep.package, SHA_package)
        # The SHA stdlib is a weird case, because it has had both 1.x.y versions and 0.7.x versions.
        # So we need to support both.
        # (plus "< 0.0.1", of course).
        compat_entry = "<0.0.1, 0.7, 1"
    else
        # For all other stdlibs, just 1.x.y is sufficient.
        # (plus "< 0.0.1", of course).
        compat_entry = "< 0.0.1, 1"
    end
    return compat_entry
end

function ensure_stdlib_entry_supports_older_julia(compat_entry::String)
    # On older versions of Julia, when you run `Pkg.test()`, Pkg will set the versions
    # of all stdlibs to v0.0.0
    #
    # Therefore, if a package Foo.jl depends on stdlib Bar, and if Foo.jl's [compat] entry
    # for Bar does not cover v0.0.0, then when you run `Pkg.test("MyPackage)`, you will get
    # an error. This occurs even if Foo.jl is an indirect (recursive) dependency of MyPackage.
    #
    # Therefore, if  Foo.jl's [compat] entry for Bar does not cover v0.0.0, then we can see
    # widespread breakage (throughout the ecosystem) whenever people try to run their package
    # tests (either locally or in CI) on older versions of Julia. We don't want that kind of
    # breakage (even if the Julia versions are a little old),
    #
    # Note: To reduce noise, we won't open a PR if the only change would be e.g.
    # "1, 2" ---> "< 0.0.1, 1, 2".
    # We'll only open a PR if there is some other change (a non-"< 0.0.1" change) that we are
    # already going to open a PR for. And in that case, we'll just include the "< 0.0.1" in
    # that same PR.
    # Hopefully this will reduce noise.

    compat_spec = Pkg.Types.semver_spec(compat_entry)
    if v"0.0.0" ∉ compat_spec
        compat_entry = "< 0.0.1, " * compat_entry
    end
    return compat_entry
end

function compat_version_number(ver::VersionNumber)
    (ver.major > 0) && return "$(ver.major)"
    (ver.minor > 0) && return "0.$(ver.minor)"

    return "0.0.$(ver.patch)"
end

function subdir_string(subdir::AbstractString)
    if !isempty(subdir)
        subdir_string = " for package $(splitpath(subdir)[end])"
    else
        subdir_string = ""
    end
end

function section_string(section::AbstractString)
    return section == "deps" ? "" : " in [$(section)]"
end

function pr_info(
    compat_entry_verbatim::Nothing,
    name::AbstractString,
    section_str::AbstractString,
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
    pr_title_prefix::String,
)
    new_pr_title = m"""
    $(pr_title_prefix)CompatHelper: add new compat entry for $(name)$(section_str) at version
    $(compat_entry_for_latest_version)$(subdir_string)$(pr_title_parenthetical)
    """

    new_pr_body = m"""
    This pull request sets the compat entry for the `$(name)` package to `$(compat_entry)`$(subdir_string).
    $(pr_body_keep_or_drop)

    Note: I have not tested your package with this new compat entry.
    It is your responsibility to make sure that your package tests pass before you merge this pull request.
    Note: Consider registering a new release of your package immediately after merging this PR, as downstream packages may depend on this for tests to pass.
    """ls

    return (strip(new_pr_title), strip(new_pr_body))
end

function pr_info(
    compat_entry_verbatim::AbstractString,
    name::AbstractString,
    section_str::AbstractString,
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
    pr_title_prefix::String,
)
    new_pr_title = m"""
    $(pr_title_prefix)CompatHelper: bump compat for $(name)$(section_str) to
    $(compat_entry_for_latest_version)$(subdir_string)$(pr_title_parenthetical)
    """

    new_pr_body = m"""
    This pull request changes the compat entry for the `$(name)` package from `$(compat_entry_verbatim)` to `$(compat_entry)`$(subdir_string).
    $(pr_body_keep_or_drop)

    Note: I have not tested your package with this new compat entry.
    It is your responsibility to make sure that your package tests pass before you merge this pull request.
    """ls

    return (strip(new_pr_title), strip(new_pr_body))
end

function skip_equality_specifiers(
    bump_compat_containing_equality_specifier::Bool,
    compat_entry_verbatim::Union{AbstractString,Nothing},
)
    # To check for an equality specifier (but not an inequality specifier) we look for an equals sign without any
    # symbols used for an inequality specifier that would also include an equals sign. Namely, greater than and
    # less than. Other specifiers containing symbols like ≥ shouldn't parse as containing an equals sign.
    return !bump_compat_containing_equality_specifier &&
           !isnothing(compat_entry_verbatim) &&
           contains(compat_entry_verbatim, '=') &&
           !contains(compat_entry_verbatim, '>') &&
           !contains(compat_entry_verbatim, '<')
end

function create_new_pull_request(
    api::GitLab.GitLabAPI,
    repo::GitLab.Project,
    new_branch_name::AbstractString,
    master_branch_name::AbstractString,
    title::AbstractString,
    body::AbstractString,
)
    return @mock GitForge.create_pull_request(
        api,
        repo.id;
        source_branch=new_branch_name,
        target_branch=master_branch_name,
        title=title,
        description=body,
    )
end

function create_new_pull_request(
    api::GitHub.GitHubAPI,
    repo::GitHub.Repo,
    new_branch_name::AbstractString,
    master_branch_name::AbstractString,
    title::AbstractString,
    body::AbstractString,
)
    return @mock GitForge.create_pull_request(
        api,
        repo.owner.login,
        repo.name;
        id=repo.id,
        head=new_branch_name,
        base=master_branch_name,
        title=title,
        body=body,
    )
end

function get_url_with_auth(api::GitHub.GitHubAPI, ci::GitHubActions, repo::GitHub.Repo)
    return "https://x-access-token:$(api.token.token)@$(ci.clone_hostname)/$(repo.full_name).git"
end

function get_url_for_ssh(::GitHub.GitHubAPI, ci::GitHubActions, repo::GitHub.Repo)
    return "git@$(ci.clone_hostname):$(repo.full_name).git"
end

function get_url_with_auth(api::GitLab.GitLabAPI, ci::GitLabCI, repo::GitLab.Project)
    return "https://oauth2:$(api.token.token)@$(ci.clone_hostname)/$(repo.path_with_namespace).git"
end

function get_url_for_ssh(::GitLab.GitLabAPI, ci::GitLabCI, repo::GitLab.Project)
    return "git@$(ci.clone_hostname):$(repo.path_with_namespace).git"
end

function continue_with_pr(dep::DepInfo, bump_compat_containing_equality_specifier::Bool)
    # Determine if we need to make a new PR
    if (!isnothing(dep.version_spec) && !isnothing(dep.latest_version)) &&
        dep.latest_version in dep.version_spec
        @info(
            "latest_version in version_spec",
            dep.latest_version,
            dep.version_spec,
            dep.package.name,
            dep,
        )

        return false
    elseif skip_equality_specifiers(
        bump_compat_containing_equality_specifier, dep.version_verbatim
    )
        @info(
            "Skipping compat entry because it contains an equality specifier",
            dep.version_verbatim,
            dep.package.name,
            dep,
        )

        return false
    elseif isnothing(dep.latest_version)
        @error(
            "The dependency was not found in any of the registries", dep.package.name, dep,
        )

        return false
    end

    return true
end

const COMPATHELPER_SSH_REMOTE_NAME = "compathelper-ssh-remote"

function make_pr_for_new_version(
    forge::Forge,
    repo::Union{GitHub.Repo,GitLab.Project},
    dep::DepInfo,
    entry_type::EntryType,
    ci_cfg::CIService;
    env=ENV,
    options::Options,
    subdir::String,
    local_clone_path::AbstractString,
    dep_section::String,
)
    if !continue_with_pr(dep, options.bump_compat_containing_equality_specifier)
        return nothing
    end

    # Get new compat entry version, pr title, and pr body text
    brand_new_compat = new_compat_entry(entry_type, dep)
    new_pr_title, new_pr_body = pr_info(
        dep.version_verbatim,
        dep.package.name,
        section_string(dep_section),
        compat_version_number(dep.latest_version),
        brand_new_compat,
        subdir_string(subdir),
        body_info(entry_type, dep.package.name),
        title_parenthetical(entry_type),
        options.pr_title_prefix,
    )

    # Make sure we haven't already created the same PR
    pr_titles = @mock get_pr_titles(forge, repo, ci_cfg.username)
    if new_pr_title in pr_titles
        @info("An open PR with the title already exists", new_pr_title)

        return nothing
    end

    # Make a dir for our SSH PrivateKey which we will use only if it has been enabled
    created_pr = nothing
    with_temp_dir(; cleanup=true) do ssh_private_key_dir
        ssh_envvar = has_ssh_private_key(; env=env)

        if ssh_envvar
            pkey_filename = create_ssh_private_key(ssh_private_key_dir; env=env)
            repo_git_url = @mock get_url_for_ssh(forge, ci_cfg, repo)
        else
            pkey_filename = nothing
            repo_git_url = @mock get_url_with_auth(forge, ci_cfg, repo)
        end

        # Go to our local clone
        cd(local_clone_path)

        # Checkout master branch
        master_branch_name = git_get_master_branch(options.master_branch)
        git_checkout(master_branch_name)

        # Create compathelper branch and check it out
        new_branch_name = "compathelper/new_version/$(get_random_string())"
        git_branch(new_branch_name; checkout=true)

        # Add new compat entry to project.toml, bump the version if needed,
        # and write it out
        modify_project_toml(
            dep.package.name,
            joinpath(local_clone_path, subdir),
            brand_new_compat,
            options.bump_version,
        )
        git_add()

        # Commit changes and make PR
        @info("Attempting to commit...")
        commit_was_success = git_commit(new_pr_title; env=env)
        if commit_was_success
            @info("Commit was a success")
            api_retry() do
                # For the first push, we intentionally push to the HTTPS remote (`origin`),
                # because we want to avoid triggering duplicate CI runs.
                @mock git_push(
                    "origin", new_branch_name, pkey_filename; force=true, env=env
                )
            end

            new_pr, _ = create_new_pull_request(
                forge, repo, new_branch_name, master_branch_name, new_pr_title, new_pr_body
            )

            options.cc_user && cc_mention_user(forge, repo, new_pr; env=env)
            options.unsub_from_prs && unsub_from_pr(forge, new_pr)

            # If we have an SSH key, we need to create a new remote (or update
            # it) with the appropriate URL (ssh/https) so that force_ci_trigger()
            # can use it
            git_remote_add_or_seturl(COMPATHELPER_SSH_REMOTE_NAME, repo_git_url)

            force_ci_trigger(forge, new_pr_title, new_branch_name, pkey_filename; env=env)

            # Return to the master branch
            git_checkout(master_branch_name)

            created_pr = new_pr
        end
    end

    return created_pr
end

function force_ci_trigger(
    api::GitLab.GitLabAPI,
    pr_title::AbstractString,
    branch_name::AbstractString,
    pkey_filename::Union{AbstractString,Nothing};
    env=ENV,
)
    # This does not need to happen for GitLab
    return nothing
end

function force_ci_trigger(
    api::GitHub.GitHubAPI,
    pr_title::AbstractString,
    branch_name::AbstractString,
    pkey_filename::Union{AbstractString,Nothing};
    env=ENV,
)
    # If we are on GitHub we need to amend the comment and force push to trigger
    # the CI. We only do this if an SSH key has been provided
    # https://github.com/JuliaRegistries/CompatHelper.jl/issues/387
    if !isnothing(pkey_filename)
        # Do a soft reset to the previous commit
        @debug "force_ci_trigger: doing a soft reset to the previous commit"
        git_reset("HEAD~1"; soft=true)

        # Sleep for 1 second to make sure the timestamp changes
        sleep(1)

        # Commit the changes once again to generate a new SHA
        @debug "force_ci_trigger: commiting again, in order to generate a new SHA"
        git_commit(pr_title; env=env)

        # Force push the changes to trigger the PR
        api_retry() do
            @debug "force_ci_trigger: force-pushing the changes to trigger CI on the PR"
            @mock git_push(
                COMPATHELPER_SSH_REMOTE_NAME,
                branch_name,
                pkey_filename;
                force=true,
                env=env,
            )
        end
    end

    return nothing
end

function cc_mention_user(
    api::GitHub.GitHubAPI, repo::GitHub.Repo, pr::GitHub.PullRequest; env=ENV
)
    username = env["GITHUB_ACTOR"]
    body = "cc @$username"

    return @mock GitForge.create_pull_request_comment(
        api, repo.owner.login, repo.name, pr.id; body=body
    )
end

function cc_mention_user(
    api::GitLab.GitLabAPI, repo::GitLab.Project, pr::GitLab.MergeRequest; env=ENV
)
    username = env["GITLAB_USER_LOGIN"]
    body = "cc @$username"

    return @mock GitForge.create_pull_request_comment(api, repo.id, pr.iid; body=body)
end

function unsub_from_pr(api::GitHub.GitHubAPI, pr::GitHub.PullRequest)
    return GitForge.unsubscribe_from_pull_request(api, pr.repo.id, pr.id)
end

function unsub_from_pr(api::GitLab.GitLabAPI, pr::GitLab.MergeRequest)
    return @mock GitForge.unsubscribe_from_pull_request(api, pr.project_id, pr.iid)
end

function modify_project_toml(
    name::AbstractString,
    repo_path::AbstractString,
    brand_new_compat::AbstractString,
    bump_version::Bool,
)
    # Open up Project.toml
    project_file = joinpath(repo_path, "Project.toml")
    project = TOML.parsefile(project_file)

    # Add the new compat
    add_compat_section!(project)
    project["compat"][name] = brand_new_compat

    # Bump the version if specified
    bump_version && bump_package_version!(project)

    # Write the file back out
    open(project_file, "w") do io
        TOML.print(
            io, project; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key)
        )
    end
end

function bump_package_version!(project::Dict)
    # do nothing if version is not defined
    !("version" in keys(project)) && return nothing

    version = VersionNumber(project["version"])

    # Only bump the version if prerelease is empty
    !isempty(version.prerelease) && return nothing

    # Bump minor if version > 1.0, else bump patch
    if version.major >= 1
        version = VersionNumber(
            version.major, version.minor + 1, 0, version.prerelease, version.build
        )
    else
        version = VersionNumber(
            version.major,
            version.minor,
            version.patch + 1,
            version.prerelease,
            version.build,
        )
    end

    project["version"] = string(version)
    return project
end

function create_ssh_private_key(dir::AbstractString; env=ENV)
    run(`chmod 700 $dir`)
    pkey_filename = joinpath(dir, "privatekey")

    @info("EnvVar `$PRIVATE_SSH_ENVVAR` is defined, nonempty, and not `false`")
    ssh_envvar_contents = env[PRIVATE_SSH_ENVVAR]
    ssh_pkey = @mock decode_ssh_private_key(ssh_envvar_contents)
    open(pkey_filename, "w") do io
        println(io, ssh_pkey)
    end
    run(`chmod 600 $pkey_filename`)

    return pkey_filename
end
