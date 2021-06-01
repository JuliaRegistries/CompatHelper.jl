struct Package
    name::String
    uuid::UUIDs.UUID
end

mutable struct CompatEntry
    package::Package
    version_number::Union{VersionNumber,Nothing}
    version_verbatim::Union{String,Nothing}

    function CompatEntry(
        package::Package;
        version_number::Union{VersionNumber,Nothing}=nothing,
        version_verbatim::Union{String,Nothing}=nothing,
    )
        return new(package, version_number, version_verbatim)
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
