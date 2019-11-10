import GitHub
import Pkg

function get_project_deps(repo::GitHub.Repo; auth::GitHub.Authorization, master_branch::Union{DefaultBranch, AbstractString})
    original_directory = pwd()
    tmp_dir = mktempdir()
    atexit(() -> rm(tmp_dir; force = true, recursive = true))
    url_with_auth = "https://x-access-token:$(auth.token)@github.com/$(repo.full_name).git"
    cd(tmp_dir)
    try
        run(`git clone $(url_with_auth) REPO`)
    catch
    end
    cd(joinpath(tmp_dir, "REPO"))
    default_branch = git_get_current_branch()
    master_branch_name = git_decide_master_branch(master_branch, default_branch)
    run(`git checkout $(master_branch_name)`)
    project_file = joinpath(tmp_dir, "REPO", "Project.toml")
    dep_to_current_compat_entry, dep_to_current_compat_entry_verbatim,
                                 dep_to_latest_version,
                                 deps_with_missing_compat_entry = get_project_deps(project_file)
    cd(original_directory)
    rm(tmp_dir; force = true, recursive = true)
    result = dep_to_current_compat_entry, dep_to_current_compat_entry_verbatim,
                                          dep_to_latest_version,
                                          deps_with_missing_compat_entry
    return result
end

function get_project_deps(project_file::String)
    dep_to_current_compat_entry = Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}}()
    dep_to_current_compat_entry_verbatim = Dict{Package, Union{String, Nothing}}()
    dep_to_latest_version = Dict{Package, Union{VersionNumber, Nothing}}()
    deps_with_missing_compat_entry = Set{Package}()
    get_project_deps!(dep_to_current_compat_entry,
                      dep_to_current_compat_entry_verbatim,
                      dep_to_latest_version,
                      deps_with_missing_compat_entry,
                      project_file)
    result = dep_to_current_compat_entry, dep_to_current_compat_entry_verbatim,
                                          dep_to_latest_version,
                                          deps_with_missing_compat_entry
    return result
end

function get_project_deps!(dep_to_current_compat_entry::Dict{Package, Union{Pkg.Types.VersionSpec, Nothing}},
                           dep_to_current_compat_entry_verbatim::Dict{Package, Union{String, Nothing}},
                           dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                           deps_with_missing_compat_entry::Set{Package},
                           project_file::String)
    project = Pkg.TOML.parsefile(project_file)
    if haskey(project, "deps")
        deps = project["deps"]
        compat = project["compat"]
        stdlib_uuids = gather_stdlib_uuids()
        for d in deps
            name = d[1]
            uuid = UUIDs.UUID(d[2])
            if uuid in stdlib_uuids
                @debug("Skipping stdlib: $(uuid)")
            elseif endswith(lowercase(strip(name)), lowercase(strip("_jll")))
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
