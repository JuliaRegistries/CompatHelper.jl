struct Package
    name::String
    uuid::UUIDs.UUID
end

mutable struct CompatEntry
    package::Package
    version_spec::Union{Pkg.Types.VersionSpec, Nothing}
    version_verbatim::Union{String, Nothing}

    function CompatEntry(p::Package)
        return new(p, nothing, nothing)
    end
end

const LOCAL_REPO_NAME = "REPO"
const GIT_COMMIT_NAME = "CompatHelper Julia"
const GIT_COMMIT_EMAIL = "compathelper_noreply@julialang.org"

git_clone(url::AbstractString, local_path::AbstractString) = run(`git clone $(url) $(local_path)`)
git_checkout(branch::AbstractString) = run(`git checkout $(branch)`)


function add_compat_section!(project::AbstractDict)
    if !haskey(project, "compat")
        project["compat"] = Dict{Any, Any}()
    end

    return project
end


function get_project_deps(
    api::GitHub.GitHubAPI, clone_hostname::AbstractString, repo::GitHub.Repo;
    subdir::AbstractString="", include_jll::Bool=false
)
    mktempdir() do f
        url_with_auth = "https://x-access-token:$(api.token)@$(clone_hostname)/$(repo.full_name).git"
        local_path = joinpath(f, LOCAL_REPO_NAME)
        @mock git_clone(url_with_auth, local_path)

        # Get all the compat dependencies from the local Project.toml file
        project_file = @mock joinpath(local_path, subdir, "Project.toml")
        deps = get_project_deps(project_file; include_jll=include_jll)

        return deps
    end
end


function get_project_deps(project_file::AbstractString; include_jll::Bool=false)
    project_deps = Set{CompatEntry}()
    project = TOML.parsefile(project_file)

    if haskey(project, "deps")
        deps = project["deps"]
        add_compat_section!(project)
        compat = project["compat"]

        for dep in deps
            name = dep[1]
            uuid = UUIDs.UUID(dep[2])

            # Ignore STDLIB packages and JLL ones if flag set
            if !Pkg.Types.is_stdlib(uuid) && (!endswith(lowercase(strip(name)), "_jll") || include_jll)
                package = Package(name, uuid)
                compat_entry = CompatEntry(package)
                dep_entry = convert(String, strip(get(compat, name, "")))

                if !isempty(dep_entry)
                    compat_entry.version_spec = Pkg.Types.semver_spec(dep_entry)
                    compat_entry.version_verbatim = dep_entry
                end

                push!(project_deps, compat_entry)
            end
        end
    end

    return project_deps
end
