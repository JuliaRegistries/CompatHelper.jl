const COMPATHELPER_GIT_COMMITTER_NAME = "CompatHelper Julia"
const COMPATHELPER_GIT_COMMITTER_EMAIL = "compathelper_noreply@julialang.org"

function get_git_name_and_email(; env=ENV)
    name = if "GIT_COMMITTER_NAME" in env
        env["GIT_COMMITTER_NAME"]
    else
        COMPATHELPER_GIT_COMMITTER_NAME
    end

    email = if "GIT_COMMITTER_EMAIL" in env
        env["GIT_COMMITTER_EMAIL"]
    else
        COMPATHELPER_GIT_COMMITTER_EMAIL
    end

    return name, email
end

git_checkout(branch::AbstractString) = run(`git checkout $(branch)`)

git_add(; items="", flags="") = run(`git add $flags $items`)

git_remote_remove(remote::AbstractString) = run(`git remote remove $remote`)
function git_remote_add(remote::AbstractString, url::AbstractString)
    return run(`git remote add $remote $url`)
end

git_reset(pathspec::AbstractString; flags="") = run(`git reset $flags "$pathspec"`)

function git_push(remote::AbstractString, branch::AbstractString; force=false, env=ENV)
    force_flag = force ? "-f" : ""
    name, email = get_git_name_and_email(; env=env)

    return run(`git -c "user.name=$name" -c "user.email=$email" push $force_flag $remote $branch`)
end

function git_commit(
    message::AbstractString="",
    pkey_filename::Union{AbstractString,Nothing}=nothing;
    env=ENV,
)
    name, email = get_git_name_and_email(; env=env)
    cmd = `git -c "user.name=$name" -c "user.email=$email" commit -m $message`

    result = try
        withenv("GIT_SSH_COMMAND" => isnothing(pkey) ? "ssh" : "ssh -i $pkey_filename")do
            p = pipeline(cmd; stdout=stdout, stderr=stderr)
            success(p)
        end
    catch
        false
    end
    return result
end

function git_branch(branch::AbstractString; checkout=false)
    run(`git branch $(branch)`)
    checkout && git_checkout(branch)
end

function git_clone(
    url::AbstractString,
    local_path::AbstractString,
    pkey_filename::Union{AbstractString,Nothing}=nothing,
)
    withenv("GIT_SSH_COMMAND" => isnothing(pkey) ? "ssh" : "ssh -i $pkey_filename") do
        run(`git clone $(url) $(local_path)`)
    end
end

function git_get_master_branch(master_branch::Union{DefaultBranch,AbstractString})
    current_branch = strip(read(`git rev-parse --abbrev-ref HEAD`, String))::String
    return git_decide_master_branch(master_branch, current_branch)
end

function git_decide_master_branch(master_branch::DefaultBranch)
    return strip(read(`git rev-parse --abbrev-ref HEAD`, String))::String
end

function git_decide_master_branch(master_branch::AbstractString)
    return master_branch
end
