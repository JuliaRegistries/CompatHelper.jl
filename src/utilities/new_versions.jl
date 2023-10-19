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

function new_compat_entry(
    ::KeepEntry, old_compat::AbstractString, new_compat::AbstractString
)
    return "$(strip(old_compat)), $(strip(new_compat))"
end

function new_compat_entry(
    ::Union{DropEntry,NewEntry}, old_compat::AbstractString, new_compat::AbstractString
)
    return "$(strip(new_compat))"
end

function new_compat_entry(::EntryType, old_compat::Nothing, new_compat::AbstractString)
    return "$(strip(new_compat))"
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

function pr_info(
    compat_entry_verbatim::Nothing,
    name::AbstractString,
    section::AbstractString,
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
    pr_title_prefix::String,
)
    new_pr_title = m"""
    $(pr_title_prefix)CompatHelper: add new compat entry for $(name) in $(section) at version
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
    section::AbstractString,
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
    pr_title_prefix::String,
)
    new_pr_title = m"""
    $(pr_title_prefix)CompatHelper: bump compat for $(name) in $(section) to
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
    compat_entry_for_latest_version = compat_version_number(dep.latest_version)
    brand_new_compat = new_compat_entry(
        entry_type, dep.version_verbatim, compat_entry_for_latest_version
    )
    new_pr_title, new_pr_body = pr_info(
        dep.version_verbatim,
        dep.package.name,
        dep_section,
        compat_entry_for_latest_version,
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
                @mock git_push(
                    "origin", new_branch_name, pkey_filename; force=true, env=env
                )
            end

            new_pr, _ = create_new_pull_request(
                forge, repo, new_branch_name, master_branch_name, new_pr_title, new_pr_body
            )

            options.cc_user && cc_mention_user(forge, repo, new_pr; env=env)
            options.unsub_from_prs && unsub_from_pr(forge, new_pr)
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
        git_reset("HEAD~1"; soft=true)

        # Sleep for 1 second to make sure the timestamp changes
        sleep(1)

        # Commit the changes once again to generate a new SHA
        git_commit(pr_title; env=env)

        # Force push the changes to trigger the PR
        api_retry() do
            @mock git_push("origin", branch_name, pkey_filename; force=true, env=env)
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
