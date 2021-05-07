gather_stdlib_uuids() = Set{UUIDs.UUID}(x for x in keys(Pkg.Types.stdlibs()))
