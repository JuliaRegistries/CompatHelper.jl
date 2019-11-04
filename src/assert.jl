AlwaysAssertionError() = AlwaysAssertionError("")

function always_assert(cond::Bool)
    cond || throw(AlwaysAssertionError())
    return nothing
end
