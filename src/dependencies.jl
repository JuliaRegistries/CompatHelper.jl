const LOCAL_REPO_NAME = "REPO"

function get_project_deps(
    api::Forge,
    ci::CIService,
    repo::Union{GitHub.Repo,GitLab.Project};
    options::Options,
    subdir::AbstractString,
)
    mktempdir() do f
        url_with_auth = get_url_with_auth(api, ci, repo)
        local_path = joinpath(f, LOCAL_REPO_NAME)
        @mock git_clone(url_with_auth, local_path)

        @mock cd(local_path) do
            master_branch = @mock git_get_master_branch(options.master_branch)
            @mock git_checkout(master_branch)
        end

        # Get all the compat dependencies from the local Project.toml file
        project_file = @mock joinpath(local_path, subdir, "Project.toml")
        deps = get_project_deps(project_file; include_jll=options.include_jll)

        return deps
    end
end

function get_project_deps(project_file::AbstractString; include_jll::Bool=false)
    project_deps = Set{DepInfo}()
    project = TOML.parsefile(project_file)

    if haskey(project, "deps")
        deps = project["deps"]
        add_compat_section!(project)
        compat = project["compat"]

        for dep in deps
            name = dep[1]
            uuid = UUIDs.UUID(dep[2])

            # Ignore STDLIB packages and JLL ones if flag set
            if !Pkg.Types.is_stdlib(uuid) &&
                (!endswith(lowercase(strip(name)), "_jll") || include_jll)
                package = Package(name, uuid)
                compat_entry = DepInfo(package)
                dep_entry = convert(String, strip(get(compat, name, "")))

                if !isempty(dep_entry)
                    compat_entry.version_spec = semver_spec(dep_entry)
                    compat_entry.version_verbatim = dep_entry
                end

                push!(project_deps, compat_entry)
            end
        end
    end

    return project_deps
end

function clone_all_registries(f::Function, registry_list::Vector{Pkg.RegistrySpec})
    registry_temp_dirs = Vector{String}()

    tmp_dir = @mock mktempdir(; cleanup=true)

    for registry in registry_list
        local_registry_path = joinpath(tmp_dir, "registries", registry.name)
        @mock git_clone(registry.url, local_registry_path)
    end

    registries = RegistryInstances.reachable_registries(; depots = tmp_dir)

    f(registries)

    @mock rm(tmp_dir; force=true, recursive=true)

    nothing
end

function get_latest_version!(deps::Set{DepInfo}, registries::Vector{RegistryInstances.RegistryInstance}; options::Options)
    for registry_instance in registries
        packages = registry_instance.pkgs

        for dep in deps
            uuid = (dep.package.uuid)::UUIDs.UUID

            if uuid in keys(packages)
                pkginfo = RegistryInstances.registry_info(packages[uuid])
                versions = [k for (k, v) in pkginfo.version_info if options.include_yanked || !v.yanked]

                max_version = maximum(versions)
                dep.latest_version = _max(dep.latest_version, max_version)
            end
        end
    end
end

function get_existing_registries!(deps::Set{DepInfo}, depot::String; options::Options)
    registries = RegistryInstances.reachable_registries(; depots = depot)
    get_latest_version!(deps, registries; options)

    return deps
end

function get_latest_version_from_registries!(
    deps::Set{DepInfo}, registry_list::Vector{Pkg.RegistrySpec}; options::Options
)
    @mock clone_all_registries(registry_list) do registry_temp_dirs
        get_latest_version!(deps, registry_temp_dirs; options)
    end

    return deps
end
