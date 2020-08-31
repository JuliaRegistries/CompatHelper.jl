import Pkg
import UUIDs

function git_clone(tmp_dir, previous_directory, url, name)
    cd(tmp_dir)
    run(`git clone $(url) $(name)`)
    cd(previous_directory)
end

function download_or_clone(tmp_dir, previous_director, reg_url, registry_path, url, name)
    try
        Pkg.Types.download_verify_unpack(reg_url, nothing, registry_path, ignore_existence = true)
    catch err
        # in case of fail, fallback to clone
        git_clone(tmp_dir, previous_director, url, name)
    end
end

function get_latest_version_from_registries!(dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                             registry_list::Vector{Pkg.Types.RegistrySpec};
                                             use_pkg_server::Bool=false)
    original_directory = pwd()
    num_registries = length(registry_list)
    registry_temp_dirs = Vector{String}(undef, num_registries)
    registry_urls = nothing
    for (i, registry) in enumerate(registry_list)
        tmp_dir = mktempdir()
        atexit(() -> rm(tmp_dir; force = true, recursive = true))
        registry_temp_dirs[i] = tmp_dir
        name = registry.name
        url = registry.url
        uuid = registry.uuid
        previous_directory = pwd()
        if use_pkg_server
            registry_path = joinpath(tmp_dir, name)
            @static if VERSION >= v"1.5.0"
                # copied from https://github.com/JuliaLang/Pkg.jl/blob/release-1.5/src/Types.jl#L981
                reg_url, registry_urls = pkg_server_registry_url(uuid, registry_urls)
            elseif v"1.4.0" <= VERSION < v"1.5.0"
                # copied from https://github.com/JuliaLang/Pkg.jl/blob/v1.4.2/src/Types.jl#L921
                reg_url = Pkg.Types.pkg_server_registry_url(uuid)
            else
                reg_url = nothing
            end

            if reg_url !== nothing
                download_or_clone(tmp_dir, previous_directory, reg_url, registry_path, url, name)
            elseif url !== nothing # clone from url
                git_clone(tmp_dir, previous_directory, url, name)
            else
                error("Could not download registry, nor pkg server not git download works.")
            end
        else
            git_clone(tmp_dir, previous_directory, url, name)
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
