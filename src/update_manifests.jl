function update_manifests(path::AbstractString = pwd();
                          registries::Vector{Pkg.Types.RegistrySpec} = default_registries,
                          delete_old_manifest::Bool = false)
    environments_to_update = Vector{String}(undef, 0)
    for (root, dirs, files) in walkdir(path)
        for file in files
            if (file == "Manifest.toml") | (file == "JuliaManifest.toml")
                environment = joinpath(path, root)
                push!(environments_to_update, environment)
            end
        end
    end
    unique!(environments_to_update)
    _update_manifests(environments_to_update;
                      registries = registries,
                      delete_old_manifest = delete_old_manifest)
    return nothing
end

function _update_manifests(environments::AbstractVector{<:AbstractString};
                           registries::Vector{Pkg.Types.RegistrySpec},
                           delete_old_manifest::Bool)
    for environment in environments
        _update_manifest(environment;
                         registries = registries,
                         delete_old_manifest = delete_old_manifest)
    end
    return nothing
end

function _has_project(environment::AbstractString)
    return (ispath(joinpath(environment, "Project.toml"))) |
           (ispath(joinpath(environment, "JuliaProject.toml")))
end

function _update_manifest(environment::AbstractString;
                          registries::Vector{Pkg.Types.RegistrySpec},
                          delete_old_manifest::Bool)
    @info("Updating environment: $(environment)")
    if _has_project(environment) && delete_old_manifest
        @debug("Removing Manifest.toml if it exists")
        rm(joinpath(environment, "Manifest.toml");
           force = true, recursive = true)
        @debug("Removing JuliaManifest.toml if it exists")
        rm(joinpath(environment, "JuliaManifest.toml");
           force = true, recursive = true)
    end
    with_tmp_dir() do tmp_dir
        code = """
            using Pkg;
            using UUIDs;
            Pkg.Types.RegistrySpec(name::Union{Nothing, String},
                                   uuid::Union{Nothing, UUID},
                                   url::Union{Nothing, String},
                                   path::Union{Nothing, String}) = Pkg.Types.RegistrySpec(;
                                                                                          name = name,
                                                                                          uuid = uuid,
                                                                                          url = url,
                                                                                          path = path)
            registries = $(registries);
            for registry in registries;
                Pkg.Registry.add(registry);
            end;
            Pkg.activate("$(environment)"; shared = false);
            Pkg.instantiate();
            Pkg.update();
            """
        cmd = Cmd(`$(Base.julia_cmd()) -e $(code)`;
                  env = Dict("PATH" => ENV["PATH"],
                             "JULIA_DEPOT_PATH" => tmp_dir))
        run(pipeline(cmd, stdout=stdout, stderr=stderr))
        return nothing
    end
    return nothing
end
