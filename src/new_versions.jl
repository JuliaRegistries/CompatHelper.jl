import GitHub
import Pkg

function make_pr_for_new_version(precommit_hook::Function,
                                 repo::GitHub.Repo,
                                 dep_to_current_compat_entry::Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}},
                                 dep_to_current_compat_entry_verbatim::Dict{Package, Union{String, Nothing}},
                                 dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                 deps_with_missing_compat_entry::Set{Package},
                                 pr_list::Vector{GitHub.PullRequest},
                                 pr_titles::Vector{String};
                                 auth::GitHub.Authorization,
                                 keep_existing_compat::Bool,
                                 drop_existing_compat::Bool,
                                 master_branch::Union{DefaultBranch, AbstractString})
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
                                pr_titles;
                                auth = auth,
                                master_branch = master_branch,
                                keep_existing_compat = keep_existing_compat,
                                drop_existing_compat = drop_existing_compat)
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
                                 pr_titles::Vector{String};
                                 auth::GitHub.Authorization,
                                 keep_existing_compat::Bool,
                                 drop_existing_compat::Bool,
                                 master_branch::Union{DefaultBranch, AbstractString})
    original_directory = pwd()
    always_assert(keep_existing_compat || drop_existing_compat)
    if keep_existing_compat && drop_existing_compat
        parenthetical_in_pr_title = true
    else
        parenthetical_in_pr_title = false
    end
    name = dep.name
    current_compat_entry = dep_to_current_compat_entry[dep]
    current_compat_entry_verbatim = dep_to_current_compat_entry_verbatim[dep]
    latest_version = dep_to_latest_version[dep]
    if !isnothing(current_compat_entry) && latest_version in current_compat_entry
        @info("latest_version in current_compat_entry", current_compat_entry, latest_version)
    else
        if latest_version.major == 0 && latest_version.minor == 0
            compat_entry_for_latest_version = "0.0.$(latest_version.patch)"
        else
            compat_entry_for_latest_version = "$(latest_version.major).$(latest_version.minor)"
        end
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
                                    pr_titles;
                                    auth = auth,
                                    keep_or_drop = :drop,
                                    parenthetical_in_pr_title = parenthetical_in_pr_title,
                                    master_branch = master_branch)
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
                                    pr_titles;
                                    auth = auth,
                                    keep_or_drop = :keep,
                                    parenthetical_in_pr_title = parenthetical_in_pr_title,
                                    master_branch = master_branch)
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
                                 pr_titles::Vector{String};
                                 auth::GitHub.Authorization,
                                 keep_or_drop::Symbol,
                                 parenthetical_in_pr_title::Bool,
                                 master_branch::Union{DefaultBranch, AbstractString})
    original_directory = pwd()
    always_assert(keep_or_drop == :keep || keep_or_drop == :drop)
    if keep_or_drop == :keep
        pr_body_keep_or_drop = string("This keeps the compat entries for ",
                                      "earlier versions.\n\n")
    end
    if keep_or_drop == :drop
        pr_body_keep_or_drop = string("This drops the compat entries for ",
                                      "earlier versions.\n\n")
    end
    name = dep.name
    if dep_to_current_compat_entry_verbatim[dep] isa Nothing
        new_pr_body = string("This pull request sets the compat ",
                             "entry for the `$(name)` package ",
                             "to `$(new_compat_entry)`.\n\n",
                             "$(pr_body_keep_or_drop)",
                             "Note: I have not tested your package ",
                             "with this new compat entry. ",
                             "It is your responsibility to make sure that ",
                             "your package tests pass before you merge this ",
                             "pull request.")
    else
        old_compat_entry_verbatim = convert(String, strip(dep_to_current_compat_entry_verbatim[dep]))
        new_pr_body = string("This pull request changes the compat ",
                             "entry for the `$(name)` package ",
                             "from `$(old_compat_entry_verbatim)` ",
                             "to `$(new_compat_entry)`.\n\n",
                             "$(pr_body_keep_or_drop)",
                             "Note: I have not tested your package ",
                             "with this new compat entry. ",
                             "It is your responsibility to make sure that ",
                             "your package tests pass before you merge this ",
                             "pull request.")
    end

    pr_title_parenthetical = ""
    if keep_or_drop == :keep && parenthetical_in_pr_title
        pr_title_parenthetical = " (keep existing compat)"
    end
    if keep_or_drop == :drop && parenthetical_in_pr_title
        pr_title_parenthetical = " (drop existing compat)"
    end
    new_pr_title = "CompatHelper: bump compat for \"$(name)\" to \"$(compat_entry_for_latest_version)\"$(pr_title_parenthetical)"
    if new_pr_title in pr_titles
        @info("An open PR with the title already exists", new_pr_title)
    else
        url_with_auth = "https://x-access-token:$(auth.token)@github.com/$(repo.full_name).git"
        tmp_dir = mktempdir()
        atexit(() -> rm(tmp_dir; force = true, recursive = true))
        cd(tmp_dir)
        try
            run(`git clone $(url_with_auth) REPO`)
        catch
        end
        cd(joinpath(tmp_dir, "REPO"))
        default_branch = convert(String, strip(read(`git rev-parse --abbrev-ref HEAD`, String)))::String
        if master_branch isa DefaultBranch
            master_branch_name = default_branch
        else
            master_branch_name = strip(master_branch)
        end
        cmd_checkout_master = `git checkout $(master_branch_name)`
        pipeline_checkout_master = pipeline(cmd_checkout_master;
                                            stdout=stdout,
                                            stderr=stderr)
        try
            run(pipeline_checkout_master)
        catch
        end
        new_branch_name = "compathelper/new_version/$(get_random_string())"
        run(`git branch $(new_branch_name)`)
        run(`git checkout $(new_branch_name)`)
        project_file = joinpath(tmp_dir, "REPO", "Project.toml")
        project = Pkg.TOML.parsefile(project_file)

        project["compat"][name] = new_compat_entry

        rm(project_file; force = true, recursive = true)
        open(project_file, "w") do io
            Pkg.TOML.print(io,
                           project;
                           sorted = true,
                           by = key -> (Pkg.Types.project_key_order(key), key))
        end
        try
            run(`git add -A`)
        catch
        end
        precommit_hook()
        try
            run(`git add -A`)
        catch
        end
        commit_message = "Automated commit by CompatHelper.jl"
        commit_was_success = git_make_commit(; commit_message = commit_message)
        if commit_was_success
            try
                run(`git push origin $(new_branch_name)`)
            catch
            end
            create_new_pull_request(repo;
                                    base_branch = default_branch,
                                    head_branch = new_branch_name,
                                    title = new_pr_title,
                                    body = new_pr_body,
                                    auth = auth,)
        else
            @info("Commit was not a success")
        end
        cd(original_directory)
        rm(tmp_dir; force = true, recursive = true)
    end
    cd(original_directory)
    return nothing
end
