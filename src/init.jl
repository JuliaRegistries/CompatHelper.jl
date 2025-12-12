const STDLIB_SET = Ref{Set{Package}}()

function initialize_stdlib_set()
    set = Set{Package}()

    stdlibs_from_pkg = Pkg.Types.stdlibs()
    for (uuid, info) in pairs(stdlibs_from_pkg)
        name = info[1]
        push!(set, Package(name, uuid))
    end

    STDLIB_SET[] = set
end

# Like `in`, but enforcing correct types
function typed_in(element::T, set::Set{T}) where {T}
    return element in set
end

function is_stdlib(p::Package)
    # Not thread-safe, but we don't use multiple threads in this package, so not really a problem.
    return typed_in(p, STDLIB_SET[])
end

function __init__()
    initialize_stdlib_set()
    return nothing
end
