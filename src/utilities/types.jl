abstract type EntryType end
struct KeepEntry <: EntryType end
struct DropEntry <: EntryType end
struct NewEntry <: EntryType end

struct DefaultBranch end

struct Package
    name::String
    uuid::UUIDs.UUID
end

mutable struct DepInfo
    package::Package
    latest_version::Union{VersionNumber,Nothing}
    version_spec::Union{VersionSpec,Nothing}
    version_verbatim::Union{String,Nothing}

    function DepInfo(
        package::Package;
        latest_version::Union{VersionNumber,Nothing}=nothing,
        version_spec::Union{VersionSpec,Nothing}=nothing,
        version_verbatim::Union{String,Nothing}=nothing,
    )
        return new(package, latest_version, version_spec, version_verbatim)
    end
end

function Base.in(p::Package, s::Set{DepInfo})
    for i in s
        if i.package == p
            return true
        end
    end

    return false
end

const DEFAULT_REGISTRIES = Pkg.RegistrySpec[Pkg.RegistrySpec(;
    name="General",
    uuid="23338594-aafe-5451-b93e-139f81909106",
    url="https://github.com/JuliaRegistries/General.git",
)]

Base.@kwdef struct Options
    entry_type::EntryType                              = KeepEntry()
    registries::Vector{Pkg.RegistrySpec}               = DEFAULT_REGISTRIES
    use_existing_registries::Bool                      = false
    depot::String                                      = DEPOT_PATH[1]
    subdirs::Vector{String}                            = [""]
    master_branch::Union{DefaultBranch,AbstractString} = DefaultBranch()
    bump_compat_containing_equality_specifier::Bool    = true
    pr_title_prefix::String                            = ""
    include_jll::Bool                                  = false
    unsub_from_prs::Bool                               = false
    cc_user::Bool                                      = false
    bump_version::Bool                                 = false
end
