function gather_stdlib_uuids()
    return Set{UUIDs.UUID}(x for x in keys(Pkg.Types.stdlibs()))
end
