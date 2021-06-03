struct Package
    name::String
    uuid::UUIDs.UUID
end

mutable struct CompatEntry
    package::Package
    latest_version::Union{VersionNumber,Nothing}
    version_spec::Union{VersionSpec,Nothing}
    version_verbatim::Union{String,Nothing}

    function CompatEntry(
        package::Package;
        latest_version::Union{VersionNumber,Nothing}=nothing,
        version_spec::Union{VersionSpec,Nothing}=nothing,
        version_verbatim::Union{String,Nothing}=nothing,
    )
        return new(package, latest_version, version_spec, version_verbatim)
    end
end

function Base.in(p::Package, s::Set{CompatEntry})
    for i in s
        if i.package == p
            return true
        end
    end

    return false
end
