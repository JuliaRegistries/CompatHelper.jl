git_checkout(branch::AbstractString) = run(`git checkout $(branch)`)

git_add(; items="", flags="") = run(`git add $flags $items`)

git_remote_remove(remote::AbstractString) = run(`git remote remove $remote`)
git_remote_add(remote::AbstractString, url::AbstractString) = run(`git remote add $remote $url`)

git_reset(pathspec::AbstractString; flags="") = run(`git reset $flags "$pathspec"`)

function git_push(remote::AbstractString, branch::AbstractString; force=false)
    force_flag = force ? "-f" : ""

    # TODO: Inject username/email here
    run(`git push $force_flag $remote $branch`)
end

function git_commit(message::AbstractString="")
    result = try
        # TODO: Inject username/email here
        cmd = `git commit -m $message`
        p = pipeline(cmd; stdout=stdout, stderr=stderr)
        success(p)
    catch
        false
    end
    return result
end

function git_branch(branch::AbstractString; checkout=false)
    run(`git branch $(branch)`)
    checkout && git_checkout(branch)
end

function git_clone(url::AbstractString, local_path::AbstractString)
    return run(`git clone $(url) $(local_path)`)
end

function git_get_master_branch(master_branch::Union{DefaultBranch,AbstractString})
    current_branch = strip(read(`git rev-parse --abbrev-ref HEAD`, String))::String
    return git_decide_master_branch(master_branch, current_branch)
end

function git_decide_master_branch(master_branch::DefaultBranch, default_branch::String)
    return default_branch
end

function git_decide_master_branch(master_branch::AbstractString, default_branch::String)
    return strip(master_branch)::String
end
