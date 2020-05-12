import GitHub
import Pkg

function make_pr_for_new_version(precommit_hook::Function,
                                 repo::GitHub.Repo,
                                 dep_to_current_compat_entry::Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}},
                                 dep_to_current_compat_entry_verbatim::Dict{Package, Union{String, Nothing}},
                                 dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                 deps_with_missing_compat_entry::Set{Package},
                                 pr_list::Vector{GitHub.PullRequest},
                                 pr_titles::Vector{String},
                                 ci_cfg::CIService;
                                 auth::GitHub.Authorization,
                                 env,
                                 keep_existing_compat::Bool,
                                 drop_existing_compat::Bool,
                                 master_branch::Union{DefaultBranch, AbstractString},
                                 subdir::AbstractString,
                                 pr_title_prefix::String,
                                 registries::Vector{Pkg.Types.RegistrySpec})
    original_directory = pwd()
    always_assert(keep_existing_compat || drop_existing_compat)
    for dep in keys(dep_to_current_compat_entry)
        make_pr_for_new_version(precommit_hook,
                                repo,
                                dep,
                                dep_to_current_compat_entry,
                                dep_to_current_compat_entry_verbatim,
                                dep_to_latest_version,
                                pr_list,
                                pr_titles,
                                ci_cfg;
                                auth = auth,
                                env = env,
                                master_branch = master_branch,
                                subdir = subdir,
                                keep_existing_compat = keep_existing_compat,
                                drop_existing_compat = drop_existing_compat,
                                pr_title_prefix = pr_title_prefix,
                                registries = registries)
    end
    cd(original_directory)
    return nothing
end

function make_pr_for_new_version(precommit_hook::Function,
                                 repo::GitHub.Repo,
                                 dep::Package,
                                 dep_to_current_compat_entry::Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}},
                                 dep_to_current_compat_entry_verbatim::Dict{Package, Union{String, Nothing}},
                                 dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                 pr_list::Vector{GitHub.PullRequest},
                                 pr_titles::Vector{String},
                                 ci_cfg::CIService;
                                 auth::GitHub.Authorization,
                                 env,
                                 keep_existing_compat::Bool,
                                 drop_existing_compat::Bool,
                                 master_branch::Union{DefaultBranch, AbstractString},
                                 subdir::AbstractString,
                                 pr_title_prefix::String,
                                 registries::Vector{Pkg.Types.RegistrySpec})
    original_directory = pwd()
    always_assert(keep_existing_compat || drop_existing_compat)
    parenthetical_in_pr_title = keep_existing_compat && drop_existing_compat
    name = dep.name
    current_compat_entry = dep_to_current_compat_entry[dep]
    current_compat_entry_verbatim = dep_to_current_compat_entry_verbatim[dep]
    latest_version = dep_to_latest_version[dep]
    if !isnothing(latest_version) && !isnothing(current_compat_entry) && latest_version in current_compat_entry
        @info("latest_version in current_compat_entry",
              current_compat_entry,
              latest_version,
              name,
              dep)
    else
        if isnothing(latest_version)
            @error("The dependency was not found in any of the registries", name, dep)
            cd(original_directory)
            return nothing
        end
        compat_entry_for_latest_version = generate_compat_entry(latest_version)
        if isnothing(current_compat_entry)
            brand_new_compat = old_compat_to_new_compat(nothing,
                                                        compat_entry_for_latest_version,
                                                        :brandnewentry)
            make_pr_for_new_version(precommit_hook,
                                    compat_entry_for_latest_version,
                                    brand_new_compat,
                                    repo,
                                    dep,
                                    dep_to_current_compat_entry,
                                    dep_to_current_compat_entry_verbatim,
                                    dep_to_latest_version,
                                    pr_list,
                                    pr_titles,
                                    ci_cfg;
                                    auth = auth,
                                    env = env,
                                    keep_or_drop = :brandnewentry,
                                    parenthetical_in_pr_title = false,
                                    master_branch = master_branch,
                                    subdir = subdir,
                                    pr_title_prefix = pr_title_prefix,
                                    registries = registries)
        else
            if drop_existing_compat
                drop_compat = old_compat_to_new_compat(current_compat_entry_verbatim,
                                                       compat_entry_for_latest_version,
                                                       :drop)
                make_pr_for_new_version(precommit_hook,
                                        compat_entry_for_latest_version,
                                        drop_compat,
                                        repo,
                                        dep,
                                        dep_to_current_compat_entry,
                                        dep_to_current_compat_entry_verbatim,
                                        dep_to_latest_version,
                                        pr_list,
                                        pr_titles,
                                        ci_cfg;
                                        auth = auth,
                                        env = env,
                                        keep_or_drop = :drop,
                                        parenthetical_in_pr_title = parenthetical_in_pr_title,
                                        master_branch = master_branch,
                                        subdir = subdir,
                                        pr_title_prefix = pr_title_prefix,
                                        registries = registries)
            end
            if keep_existing_compat
                keep_compat = old_compat_to_new_compat(current_compat_entry_verbatim,
                                                       compat_entry_for_latest_version,
                                                       :keep)
                make_pr_for_new_version(precommit_hook,
                                        compat_entry_for_latest_version,
                                        keep_compat,
                                        repo,
                                        dep,
                                        dep_to_current_compat_entry,
                                        dep_to_current_compat_entry_verbatim,
                                        dep_to_latest_version,
                                        pr_list,
                                        pr_titles,
                                        ci_cfg;
                                        auth = auth,
                                        env = env,
                                        keep_or_drop = :keep,
                                        parenthetical_in_pr_title = parenthetical_in_pr_title,
                                        master_branch = master_branch,
                                        subdir = subdir,
                                        pr_title_prefix = pr_title_prefix,
                                        registries = registries)
            end
        end
    end
    cd(original_directory)
    return nothing
end

@inline function old_compat_to_new_compat(old_compat::String,
                                          new_compat::String,
                                          keep_or_drop::Symbol)::String
    if keep_or_drop == :keep
        return "$(strip(old_compat)), $(strip(new_compat))"
    elseif keep_or_drop == :drop
        return "$(strip(new_compat))"
    else
        throw(ArgumentError("keep_or_drop must be either :keep or :drop"))
    end
end

@inline function old_compat_to_new_compat(old_compat::Nothing,
                                          new_compat::String,
                                          keep_or_drop::Symbol)::String
    return "$(strip(new_compat))"
end

function make_pr_for_new_version(precommit_hook::Function,
                                 compat_entry_for_latest_version::String,
                                 new_compat_entry::String,
                                 repo::GitHub.Repo,
                                 dep::Package,
                                 dep_to_current_compat_entry::Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}},
                                 dep_to_current_compat_entry_verbatim::Dict{Package, Union{String, Nothing}},
                                 dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                 pr_list::Vector{GitHub.PullRequest},
                                 pr_titles::Vector{String},
                                 ci_cfg::CIService;
                                 auth::GitHub.Authorization,
                                 env,
                                 keep_or_drop::Symbol,
                                 parenthetical_in_pr_title::Bool,
                                 master_branch::Union{DefaultBranch, AbstractString},
                                 subdir::AbstractString,
                                 pr_title_prefix::String,
                                 registries::Vector{Pkg.Types.RegistrySpec})
    original_directory = pwd()
    name = dep.name
    if subdir != ""
        subdir_string = " for package $(splitpath(subdir)[end])"
    else
        subdir_string = ""
    end
    always_assert(keep_or_drop == :keep || keep_or_drop == :drop || keep_or_drop == :brandnewentry)
    if keep_or_drop == :keep
        pr_body_keep_or_drop = string("This keeps the compat entries for ",
                                      "earlier versions.\n\n")
    end
    if keep_or_drop == :drop
        pr_body_keep_or_drop = string("This drops the compat entries for ",
                                      "earlier versions.\n\n")
    end
    if keep_or_drop == :brandnewentry
        pr_body_keep_or_drop = string("This is a brand new compat entry. ",
                                      "Previously, you did not have a ",
                                      "compat entry for the ",
                                      "`$(name)` package.\n\n")
    end
    pr_title_parenthetical = generate_pr_title_parenthetical(keep_or_drop,
                                                             parenthetical_in_pr_title)
    if dep_to_current_compat_entry_verbatim[dep] isa Nothing
        new_pr_title = string("$(pr_title_prefix)",
                              "CompatHelper: add new compat entry for ",
                              "\"$(name)\" at version ",
                              "\"$(compat_entry_for_latest_version)\"",
                              "$subdir_string")
        new_pr_body = string("This pull request sets the compat ",
                             "entry for the `$(name)` package ",
                             "to `$(new_compat_entry)`",
                             "$subdir_string.\n\n",
                             "$(pr_body_keep_or_drop)",
                             "Note: I have not tested your package ",
                             "with this new compat entry. ",
                             "It is your responsibility to make sure that ",
                             "your package tests pass before you merge this ",
                             "pull request. ",
                             "Note: Consider tagging a patch release immediately after ",
                             "merging this PR, as downstream packages ",
                             "may depend on this for tests to pass.")
    else
        new_pr_title = string("$(pr_title_prefix)",
                              "CompatHelper: bump compat for ",
                              "\"$(name)\" to ",
                              "\"$(compat_entry_for_latest_version)\"",
                              "$subdir_string",
                              "$(pr_title_parenthetical)")
        old_compat_entry_verbatim = convert(String, strip(dep_to_current_compat_entry_verbatim[dep]))
        new_pr_body = string("This pull request changes the compat ",
                             "entry for the `$(name)` package ",
                             "from `$(old_compat_entry_verbatim)` ",
                             "to `$(new_compat_entry)`",
                             "$subdir_string.\n\n",
                             "$(pr_body_keep_or_drop)",
                             "Note: I have not tested your package ",
                             "with this new compat entry. ",
                             "It is your responsibility to make sure that ",
                             "your package tests pass before you merge this ",
                             "pull request.")
    end
    if new_pr_title in pr_titles
        @info("An open PR with the title already exists", new_pr_title)
    else
        url_with_auth = "https://x-access-token:$(auth.token)@github.com/$(repo.full_name).git"
        url_for_ssh = "git@github.com:$(repo.full_name).git"

        tmp_dir = mktempdir()
        atexit(() -> rm(tmp_dir; force = true, recursive = true))
        cd(tmp_dir)

        ssh_private_key_directory = mktempdir()
        run(`chmod 700 $(ssh_private_key_directory)`)
        atexit(() -> rm(ssh_private_key_directory; force = true, recursive = true))

        ssh_private_key_filename = joinpath(ssh_private_key_directory, "privatekey")
        atexit(() -> rm(ssh_private_key_filename; force = true, recursive = true))

        try
            run(`git clone $(url_with_auth) REPO`)
        catch
        end
        cd(joinpath(tmp_dir, "REPO"))
        default_branch = git_get_current_branch()
        master_branch_name = git_decide_master_branch(master_branch,
                                                      default_branch)
        run(`git checkout $(master_branch_name)`)
        new_branch_name = "compathelper/new_version/$(get_random_string())"
        run(`git branch $(new_branch_name)`)
        run(`git checkout $(new_branch_name)`)
        project_file = joinpath(tmp_dir, "REPO", subdir, "Project.toml")
        project = Pkg.TOML.parsefile(project_file)
        add_compat_section!(project)
        project["compat"][name] = new_compat_entry
        rm(project_file; force = true, recursive = true)
        open(project_file, "w") do io
            Pkg.TOML.print(io,
                           project;
                           sorted = true,
                           by = key -> (Pkg.Types.project_key_order(key), key))
        end
        set_git_identity(ci_cfg)
        try
            run(`git add -A`)
        catch
        end
        if hasmethod(precommit_hook, Tuple{}, (:registries,))
            precommit_hook(; registries = registries)
        else
            precommit_hook()
        end
        try
            run(`git add -A`)
        catch
        end
        @info("Attempting to commit...")
        commit_was_success = git_make_commit(; commit_message = new_pr_title)
        if commit_was_success
            @info("Commit was a success")
            try
                run(`git push -f origin $(new_branch_name)`)
            catch
            end
            create_new_pull_request(repo;
                                    base_branch = master_branch_name,
                                    head_branch = new_branch_name,
                                    title = new_pr_title,
                                    body = new_pr_body,
                                    auth = auth,)

            COMPATHELPER_PRIV_is_defined = compathelper_priv_is_defined(env)
            @info("Environment variable `COMPATHELPER_PRIV` is defined, is nonempty, and is not the string `false`: $(COMPATHELPER_PRIV_is_defined)")
            if COMPATHELPER_PRIV_is_defined
                COMPATHELPER_PRIV_contents = env["COMPATHELPER_PRIV"]
                COMPATHELPER_PRIV = _decode_ssh_private_key(COMPATHELPER_PRIV_contents)

                rm(ssh_private_key_filename; force = true, recursive = true)
                open(ssh_private_key_filename, "w") do io
                    println(io, COMPATHELPER_PRIV)
                end
                run(`chmod 700 $(ssh_private_key_directory)`)
                run(`chmod 600 $(ssh_private_key_filename)`)

                GIT_SSH_COMMAND = "ssh -i $(ssh_private_key_filename)"

                run(`git remote remove origin`)
                run(`git remote add origin $(url_for_ssh)`)
                run(`git reset --soft "HEAD~1"`)
                git_make_commit(; commit_message = new_pr_title)
                withenv("GIT_SSH_COMMAND" => GIT_SSH_COMMAND) do
                    try
                        run(`git push -f origin $(new_branch_name)`)
                    catch
                    end
                end
            end
        end
        cd(original_directory)
        rm(ssh_private_key_filename; force = true, recursive = true)
        rm(ssh_private_key_directory; force = true, recursive = true)
        rm(tmp_dir; force = true, recursive = true)
    end
    cd(original_directory)
    return nothing
end
