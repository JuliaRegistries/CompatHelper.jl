import Pkg
import UUIDs

function get_latest_version_from_registries!(dep_to_latest_version::Dict{Package, Union{VersionNumber, Nothing}},
                                             registry_list::Vector{Pkg.Types.RegistrySpec})
      original_directory = pwd()
      num_registries = length(registry_list)
      registry_temp_dirs = Vector{String}(undef, num_registries)
      for i = 1:num_registries
          tmp_dir = mktempdir()
          atexit(() -> rm(tmp_dir; force = true, recursive = true))
          registry_temp_dirs[i] = tmp_dir
          name = registry_list[i].name
          url = registry_list[i].url
          previous_directory = pwd()
          cd(tmp_dir)
          run(`git clone $(url) $(name)`)
          cd(previous_directory)
      end
      for i = 1:num_registries
          previous_directory = pwd()
          registry_temp_dir = registry_temp_dirs[i]
          name = registry_list[i].name
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
