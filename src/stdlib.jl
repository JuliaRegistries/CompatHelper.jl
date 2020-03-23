import UUIDs

if VERSION < v"1.4"
    stdlibs = Pkg.Types.stdlib
else
    # renamed to stdlibs
    # https://github.com/JuliaLang/Pkg.jl/pull/1559
    stdlibs = Pkg.Types.stdlibs
end

# This function is based off of a similar function here:
# https://github.com/JuliaRegistries/RegistryCI.jl/blob/master/src/RegistryCI.jl
function gather_stdlib_uuids()
    return Set{UUIDs.UUID}(x for x in keys(stdlibs()))
end
