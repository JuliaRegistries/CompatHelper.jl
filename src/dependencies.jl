const LOCAL_REPO_NAME = "REPO"

function get_local_clone(
    api::Forge, ci::CIService, repo::Union{GitHub.Repo,GitLab.Project}; options
)
    f = mktempdir()
    url_with_auth = get_url_with_auth(api, ci, repo)
    local_path = joinpath(f, LOCAL_REPO_NAME)
    @mock git_clone(url_with_auth, local_path)

    @mock cd(local_path) do
        master_branch = @mock git_get_master_branch(options.master_branch)
        @mock git_checkout(master_branch)
    end

    return local_path
end

function get_project_deps(project_file::AbstractString; include_jll::Bool=false)
    project_deps = Set{DepInfo}()
    dep_section = Dict{DepInfo,String}()
    project = TOML.parsefile(project_file)

    for section in ["deps", "weakdeps", "extras"]
        if haskey(project, section)
            deps = project[section]
            add_compat_section!(project)
            compat = project["compat"]

            for dep in deps
                name = dep[1]
                uuid = UUIDs.UUID(dep[2])

                # Ignore JLL packages if flag set
                # Do NOT ignore stdlib packages.
                if !endswith(lowercase(strip(name)), "_jll") || include_jll
                    package = Package(name, uuid)
                    compat_entry = DepInfo(package)
                    dep_entry = convert(String, strip(get(compat, name, "")))

                    if !isempty(dep_entry)
                        compat_entry.version_spec = semver_spec(dep_entry)
                        compat_entry.version_verbatim = dep_entry
                    end

                    push!(project_deps, compat_entry)
                    get!(dep_section, compat_entry, section)
                end
            end
        end
    end

    return project_deps, dep_section
end

function clone_all_registries(f::Function, registry_list::Vector{Pkg.RegistrySpec})
    registry_temp_dirs = Vector{String}()

    tmp_dir = @mock mktempdir(; cleanup=true)

    for registry in registry_list
        local_registry_path = joinpath(tmp_dir, "registries", registry.name)
        @mock git_clone(registry.url, local_registry_path)
    end

    registries = RegistryInstances.reachable_registries(; depots=tmp_dir)

    f(registries)

    @mock rm(tmp_dir; force=true, recursive=true)

    return nothing
end

function get_latest_version!(
    deps::Set{DepInfo},
    registries::Vector{RegistryInstances.RegistryInstance};
    options::Options,
)
    for registry_instance in registries
        packages = registry_instance.pkgs

        for dep in deps
            uuid = (dep.package.uuid)::UUIDs.UUID

            if uuid in keys(packages)
                pkginfo = RegistryInstances.registry_info(packages[uuid])
                versions = [
                    k for
                    (k, v) in pkginfo.version_info if options.include_yanked || !v.yanked
                ]

                max_version = maximum(versions)
                dep.latest_version = _max(dep.latest_version, max_version)
            end
        end
    end
end

function get_existing_registries!(deps::Set{DepInfo}, depot::String; options::Options)
    registries = RegistryInstances.reachable_registries(; depots=depot)
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

function populate_dep_versions_from_reg!(deps; options)
    if options.use_existing_registries
        get_existing_registries!(deps, options.depot; options)
    else
        get_latest_version_from_registries!(deps, options.registries; options)
    end

    return nothing
end
