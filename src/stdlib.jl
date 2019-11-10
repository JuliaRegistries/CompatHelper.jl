import UUIDs

# This function is based off of a similar function here:
# https://github.com/JuliaRegistries/RegistryCI.jl/blob/master/src/RegistryCI.jl
function gather_stdlib_uuids()
    return Set{UUIDs.UUID}(x for x in keys(Pkg.Types.stdlib()))
end
