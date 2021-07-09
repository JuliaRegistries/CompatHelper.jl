function body_info(::KeepEntry, name::AbstractString)
    return "This keeps the compat entries for earlier versions.\n\n"
end
function body_info(::DropEntry, name::AbstractString)
    return "This drops the compat entries for earlier versions.\n\n"
end
function body_info(::NewEntry, name::AbstractString)
    return "This is a brand new compat entry. Previously, you did not have a compat entry for the `$(name)` package.\n\n"
end

title_parenthetical(::KeepEntry) = " (keep existing compat)"
title_parenthetical(::DropEntry) = " (drop existing compat)"
title_parenthetical(::NewEntry) = ""

function new_compat_entry(::EntryType, old_compat::Nothing, new_compat::AbstractString)
    return "$(strip(new_compat))"
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
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
    pr_title_prefix::String,
)
    new_pr_title = m"""
        $(pr_title_prefix)CompatHelper: add new compat entry for $(name) at version
        $(compat_entry_for_latest_version) $(subdir_string), $(pr_title_parenthetical)
    """

    new_pr_body = m"""
        This pull request sets the compat entry for the `$(name)` package to `$(compat_entry)` $(subdir_string). $(pr_body_keep_or_drop)
        Note: I have not tested your package with this new compat entry.
        It is your responsibility to make sure that your package tests pass before you merge this pull request.
        Note: Consider registering a new release of your package immediately after merging this PR, as downstream packages may depend on this for tests to pass.
    """

    return (new_pr_title, new_pr_body)
end

function pr_info(
    compat_entry_verbatim::AbstractString,
    name::AbstractString,
    compat_entry_for_latest_version::AbstractString,
    compat_entry::AbstractString,
    subdir_string::AbstractString,
    pr_body_keep_or_drop::AbstractString,
    pr_title_parenthetical::AbstractString,
    pr_title_prefix::String,
)
    new_pr_title = m"""
        $(pr_title_prefix)CompatHelper: bump compat for $(name) to
        $(compat_entry_for_latest_version) $(subdir_string), $(pr_title_parenthetical)
    """

    new_pr_body = m"""
        This pull request changes the compat entry for the `$(name)` package from `$(compat_entry_verbatim)` to `$(compat_entry)` $(subdir_string). $(pr_body_keep_or_drop)
        Note: I have not tested your package with this new compat entry.
        It is your responsibility to make sure that your package tests pass before you merge this pull request.
    """

    return (new_pr_title, new_pr_body)
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
        repo.owner.name,
        repo.name;
        id=repo.id,
        source_branch=new_branch_name,
        target_branch=master_branch_name,
        title=title,
        body=body,
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

function get_url_with_auth(
    api::GitHub.GitHubAPI, hostname::AbstractString, repo::GitHub.Repo
)
    return "https://x-access-token:$(api.token.token)@$(hostname)/$(repo.full_name).git"
end

function get_url_for_ssh(::GitHub.GitHubAPI, hostname::AbstractString, repo::GitHub.Repo)
    return "git@$(hostname):$(repo.full_name).git"
end

function get_url_with_auth(
    api::GitLab.GitLabAPI, hostname::AbstractString, repo::GitLab.Project
)
    return "https://oauth2:$(api.token.token)@$(hostname)/$(repo.path_with_namespace).git"
end

function get_url_for_ssh(::GitLab.GitLabAPI, hostname::AbstractString, repo::GitLab.Project)
    return "git@$(hostname):$(repo.path_with_namespace).git"
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
    clone_hostname::AbstractString,
    repo::Union{GitHub.Repo,GitLab.Project},
    dep::DepInfo,
    entry_type::EntryType,
    ci_cfg::CIService;
    subdir::AbstractString="",
    master_branch::Union{DefaultBranch,AbstractString}=DefaultBranch(),
    env::AbstractDict=ENV,
    bump_compat_containing_equality_specifier::Bool=true,
    pr_title_prefix::String="",
)
    if !continue_with_pr(dep, bump_compat_containing_equality_specifier)
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
        compat_entry_for_latest_version,
        brand_new_compat,
        subdir_string(subdir),
        body_info(entry_type, dep.package.name),
        title_parenthetical(entry_type),
        pr_title_prefix,
    )

    # Make sure we haven't already created the same PR
    pr_titles = @mock get_pr_titles(forge, repo, ci_cfg.username)
    if new_pr_title in pr_titles
        @info("An open PR with the title already exists", new_pr_title)

        return nothing
    end

    # Make a dir for our SSH PrivateKey which we will use only if it has been enabled
    with_temp_dir(; cleanup=true) do ssh_private_key_dir
        ssh_envvar = has_ssh_private_key(; env=env)

        if ssh_envvar
            pkey_filename = create_ssh_private_key(ssh_private_key_dir; env=env)
            repo_git_url = @mock get_url_for_ssh(forge, clone_hostname, repo)
        else
            pkey_filename = nothing
            repo_git_url = @mock get_url_with_auth(forge, clone_hostname, repo)
        end

        # In a temp dir, grab the repo, make the changes, push and make a PR
        with_temp_dir(; cleanup=true) do tmpdir
            # Clone Repo Locally
            api_retry() do
                git_clone(repo_git_url, LOCAL_REPO_NAME, pkey_filename)
            end
            cd(joinpath(tmpdir, LOCAL_REPO_NAME))

            # Checkout master branch
            master_branch_name = git_get_master_branch(master_branch)
            git_checkout(master_branch_name)

            # Create compathelper branch and check it out
            new_branch_name = "compathelper/new_version/$(get_random_string())"
            git_branch(new_branch_name; checkout=true)

            # Add new compat entry to project.toml and write it out
            add_compat_entry(
                dep.package.name,
                joinpath(tmpdir, LOCAL_REPO_NAME, subdir),
                brand_new_compat,
            )
            git_add()

            # Commit changes and make PR
            @info("Attempting to commit...")
            commit_was_success = git_commit(new_pr_title; env=env)
            if commit_was_success
                @info("Commit was a success")
                api_retry() do
                    @mock git_push("origin", new_branch_name; force=true, env=env)
                end

                create_new_pull_request(
                    forge,
                    repo,
                    new_branch_name,
                    master_branch_name,
                    new_pr_title,
                    new_pr_body,
                )
            end
        end
    end

    return nothing
end

function add_compat_entry(
    name::AbstractString, repo_path::AbstractString, brand_new_compat::AbstractString
)
    project_file = joinpath(repo_path, "Project.toml")
    project = TOML.parsefile(project_file)

    add_compat_section!(project)
    project["compat"][name] = brand_new_compat

    open(project_file, "w") do io
        TOML.print(
            io, project; sorted=true, by=key -> (Pkg.Types.project_key_order(key), key)
        )
    end
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
