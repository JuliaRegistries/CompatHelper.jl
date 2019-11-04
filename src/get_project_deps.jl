import GitHub
import Pkg

function get_project_deps(repo::GitHub.Repo; auth::GitHub.Authorization)
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
    project_file = joinpath(tmp_dir, "REPO", "Project.toml")
    dep_to_current_compat_entry, dep_to_latest_version, deps_with_missing_compat_entry = get_project_deps(project_file)
    cd(original_directory)
    rm(tmp_dir; force = true, recursive = true)
    return dep_to_current_compat_entry, dep_to_latest_version, deps_with_missing_compat_entry
end

function get_project_deps(project_file::String)
    dep_to_current_compat_entry = Dict{Package, Union{VersionNumber, Nothing}}()
    dep_to_latest_version = Dict{Package, Union{VersionNumber, Nothing}}()
    deps_with_missing_compat_entry = Set{Package}()
    get_project_deps!(dep_to_current_compat_entry, dep_to_latest_version, deps_with_missing_compat_entry, project_file)
    return dep_to_current_compat_entry, dep_to_latest_version, deps_with_missing_compat_entry
end

function get_project_deps!(dep_to_current_compat_entry::Dict{Package, Union{VersionNumber, Nothing}},
                           dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                           deps_with_missing_compat_entry::Set{Package},
                           project_file::String)
    project = Pkg.TOML.parsefile(project_file)
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
            compat_entry = convert(String, strip(get(compat, name, "")))::String
            if length(compat_entry) > 0
                compat_entry_versionnnumber = try
                    VersionNumber(compat_entry)
                catch
                    nothing
                end
            else
                push!(deps_with_missing_compat_entry, package)
                compat_entry_versionnnumber = nothing
            end
            dep_to_current_compat_entry[package] = compat_entry_versionnnumber
            dep_to_latest_version[package] = nothing
        end
    end
    return dep_to_current_compat_entry, dep_to_latest_version, deps_with_missing_compat_entry
end
