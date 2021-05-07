git_get_current_branch() = convert(String, strip(read(`git rev-parse --abbrev-ref HEAD`, String)))::String
git_decide_master_branch(master_branch::DefaultBranch, default_branch::String) = return convert(String, strip(default_branch))
git_decide_master_branch(master_branch::AbstractString, default_branch::String) = return convert(String, strip(master_branch))

function git_make_commit(; commit_message::String)
    result = try
        cmd = `git commit -m $(commit_message)`
        p = pipeline(cmd; stdout=stdout, stderr=stderr)
        success(p)
    catch
        false
    end

    return result
end
