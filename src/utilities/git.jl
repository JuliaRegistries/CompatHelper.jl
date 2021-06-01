git_checkout(branch::AbstractString) = run(`git checkout $(branch)`)

function git_clone(url::AbstractString, local_path::AbstractString)
    return run(`git clone $(url) $(local_path)`)
end
