function git_make_commit(; commit_message::String)
    result = try
        success(`git commit -m $(commit_message)`)
    catch
        false
    end
    return result
end
