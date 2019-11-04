import GitHub
import Pkg

function make_pr_for_missing_compat_entries(repo::GitHub.Repo,
                                            dep_to_current_compat_entry::Dict{Package, Union{VersionNumber, Nothing}},
                                            dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                            deps_with_missing_compat_entry::Set{Package},
                                            nonforked_pull_requests::Vector{GitHub.PullRequest},
                                            nonforked_pr_titles::Vector{String};
                                            auth::GitHub.Authorization)
    if isempty(deps_with_missing_compat_entry)
        return nothing
    end
    original_directory = pwd()
    new_pr_title = "CompatHelper: add missing compat entries"
    if new_pr_title in nonforked_pr_titles
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
        new_branch_name = "compathelper/missing_entries/$(get_random_string())"
        run(`git branch $(new_branch_name)`)
        run(`git checkout $(new_branch_name)`)
        project_file = joinpath(tmp_dir, "REPO", "Project.toml")
        project = Pkg.TOML.parsefile(project_file)

        for package in deps_with_missing_compat_entry
            latest_version = dep_to_latest_version[package]
            project["compat"][package.name] = "$(latest_version.major).$(latest_version.minor)"
        end

        rm(project_file; force = true, recursive = true)
        open(project_file, "w") do io
            Pkg.TOML.print(io,
                           project;
                           sorted = true,
                           by = key -> (Pkg.Types.project_key_order(key), key))
        end
        run(`git add -A`)
        commit_message = "Automated commit by CompatHelper.jl"
        commit_was_success = git_make_commit(; commit_message = commit_message)

        if commit_was_success
            try
                run(`git push origin $(new_branch_name)`)
            catch
            end
            new_pr_body = string("This pull request adds a compat entry for each ",
                                 "non-JLL dependency that currently does not ",
                                 "have a compat entry.\n\n",
                                 "Note: I have not tested your package ",
                                 "with these new compat entries. " ,
                                 "It is your responsibility to make sure that ",
                                 "your package tests pass before you merge this ",
                                 "pull request.")
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
