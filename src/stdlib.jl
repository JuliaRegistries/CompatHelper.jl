import UUIDs

# This function is taken from:
# https://github.com/JuliaRegistries/RegistryCI.jl/blob/master/src/RegistryCI.jl
function gather_stdlib_uuids()
    if VERSION < v"1.1"
        return Set{UUIDs.UUID}(x for x in keys(Pkg.Types.gather_stdlib_uuids()))
    else
        return Set{UUIDs.UUID}(x for x in keys(Pkg.Types.stdlib()))
    end
end
