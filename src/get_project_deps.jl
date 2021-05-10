function get_project_deps(api::GitHub.GitHubAPI,
                          clone_hostname::HostnameForClones,
                          repo::GitHub.Repo;
                          auth::GitHub.Authorization,
                          master_branch::Union{DefaultBranch, AbstractString},
                          subdir::AbstractString,
                          include_jll::Bool)
    original_directory = pwd()
    tmp_dir = mktempdir(; cleanup = true)
    url_with_auth = "https://x-access-token:$(auth.token)@$(clone_hostname.hostname)/$(repo.full_name).git"
    cd(tmp_dir)
    my_retry(() -> run(`git clone $(url_with_auth) REPO`))
    cd(joinpath(tmp_dir, "REPO"))
    default_branch = git_get_current_branch()
    master_branch_name = git_decide_master_branch(master_branch, default_branch)
    run(`git checkout $(master_branch_name)`)
    project_file = joinpath(tmp_dir, "REPO", subdir, "Project.toml")
    dep_to_current_compat_entry, dep_to_current_compat_entry_verbatim,
                                 dep_to_latest_version,
                                 deps_with_missing_compat_entry = get_project_deps(project_file; include_jll)
    cd(original_directory)
    rm(tmp_dir; force = true, recursive = true)
    result = dep_to_current_compat_entry, dep_to_current_compat_entry_verbatim,
                                          dep_to_latest_version,
                                          deps_with_missing_compat_entry
    return result
end

function get_project_deps(project_file::String; include_jll::Bool)
    dep_to_current_compat_entry = Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}}()
    dep_to_current_compat_entry_verbatim = Dict{Package, Union{String, Nothing}}()
    dep_to_latest_version = Dict{Package, Union{VersionNumber, Nothing}}()
    deps_with_missing_compat_entry = Set{Package}()
    get_project_deps!(dep_to_current_compat_entry,
                      dep_to_current_compat_entry_verbatim,
                      dep_to_latest_version,
                      deps_with_missing_compat_entry,
                      project_file;
                      include_jll)
    result = dep_to_current_compat_entry, dep_to_current_compat_entry_verbatim,
                                          dep_to_latest_version,
                                          deps_with_missing_compat_entry
    return result
end

function get_project_deps!(dep_to_current_compat_entry::Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}},
                           dep_to_current_compat_entry_verbatim::Dict{Package, Union{String, Nothing}},
                           dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                           deps_with_missing_compat_entry::Set{Package},
                           project_file::String;
                           include_jll::Bool)
    project = TOML.parsefile(project_file)
    if haskey(project, "deps")
        deps = project["deps"]
        add_compat_section!(project)
        compat = project["compat"]
        stdlib_uuids = gather_stdlib_uuids()
        for d in deps
            name = d[1]
            uuid = UUIDs.UUID(d[2])
            if uuid in stdlib_uuids
                @debug("Skipping stdlib: $(uuid)")
            elseif (endswith(lowercase(strip(name)), lowercase(strip("_jll")))) && (!include_jll)
                @debug("Skipping JLL package: $(name)")
            else
                package = Package(name, uuid)
                dep_to_latest_version[package] = nothing
                compat_entry = convert(String, strip(get(compat, name, "")))::String
                if length(compat_entry) > 0
                    dep_to_current_compat_entry_verbatim[package] = compat_entry
                    dep_to_current_compat_entry[package] = try
                        Pkg.Types.semver_spec(compat_entry)
                    catch
                        nothing
                    end
                else
                    push!(deps_with_missing_compat_entry, package)
                    dep_to_current_compat_entry[package] = nothing
                    dep_to_current_compat_entry_verbatim[package] = nothing
                end
            end
        end
    else
        @info("This project has no dependencies.")
    end
    result = dep_to_current_compat_entry, dep_to_current_compat_entry_verbatim,
                                          dep_to_latest_version,
                                          deps_with_missing_compat_entry
    return result
end
