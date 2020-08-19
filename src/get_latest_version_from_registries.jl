import Pkg
import UUIDs

function get_latest_version_from_registries!(dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                             registry_list::Vector{Pkg.Types.RegistrySpec})
    original_directory = pwd()
    num_registries = length(registry_list)
    registry_temp_dirs = Vector{String}(undef, num_registries)
    for (i, registry) enumerate(registry_list)
        tmp_dir = mktempdir()
        atexit(() -> rm(tmp_dir; force = true, recursive = true))
        registry_temp_dirs[i] = tmp_dir
        name = registry.name
        url = registry.url
        uuid = registry.uuid
        registry_path = joinpath(tmp_dir, name)
        # copied from https://github.com/JuliaLang/Pkg.jl/blob/v1.4.2/src/Types.jl#L921
        if (url = pkg_server_registry_url(uuid)) !== nothing
            # download from Pkg server
            try
                download_verify_unpack(url, nothing, registry_path, ignore_existence = true)
            catch err
                nothing
            end
        elseif reg.url !== nothing # clone from url
            LibGit2.with(GitTools.clone(ctx, url, registry_path; header = "registry from $(repr(url))")) do repo
            end
        else
            error("Could not download registry, nor pkg server not git download works.")
        end
    end
    for (registry_temp_dir, registry) in zip(registry_temp_dirs, registry_list)
        previous_directory = pwd()
        name = registry.name
        registry_path = joinpath(registry_temp_dir, name)
        cd(registry_path)
        registry_parsed = Pkg.TOML.parsefile(joinpath(registry_path, "Registry.toml"))
        packages = registry_parsed["packages"]
        for p in packages
            name = p[2]["name"]
            uuid = UUIDs.UUID(p[1])
            package = Package(name, uuid)
            path = p[2]["path"]
            if package in keys(dep_to_latest_version)
                versions = VersionNumber.(collect(keys(Pkg.TOML.parsefile(joinpath(registry_path, path, "Versions.toml")))))
                old_value = dep_to_latest_version[package]
                if isnothing(old_value)
                    dep_to_latest_version[package] = maximum(versions)
                else
                    dep_to_latest_version[package] = max(old_value, maximum(versions))
                end
            end
        end
        cd(previous_directory)
    end
    cd(original_directory)
    for tmp_dir in registry_temp_dirs
        rm(tmp_dir; force = true, recursive = true)
    end
    return dep_to_latest_version
end
