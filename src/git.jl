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
