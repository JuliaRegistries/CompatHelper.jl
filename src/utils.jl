function add_compat_section!(project::Dict)
    if !haskey(project, "compat")
        project["compat"] = Dict{Any, Any}()
    end
    return project
end

function get_random_string()
    return string(utc_to_string(now_localzone()), "-", rand(UInt32))::String
end

function generate_pr_title_parenthetical(keep_or_drop::Symbol,
                                         parenthetical_in_pr_title::Bool)::String
    if parenthetical_in_pr_title
        if keep_or_drop == :keep
            return " (keep existing compat)"
        elseif keep_or_drop == :drop
            return " (drop existing compat)"
        else
            return ""
        end
    else
        return ""
    end
end

# Fix issues where we can't delete directories because we don't have write permissions to it.
function prepare_for_deletion(path)
    try chmod(path, 0o755)
    catch; end
    for (root, dirs, files) in walkdir(path)
        for dir in dirs
            try chmod(joinpath(root, dir), 0o755)
            catch; end
        end
    end
end

function with_tmp_dir(f::Function)
    tmp_dir = mktempdir()
    atexit() do
        prepare_for_deletion(tmp_dir)
        rm(tmp_dir; force = true, recursive = true)
    end
    result = f(tmp_dir)
    prepare_for_deletion(tmp_dir)
    rm(tmp_dir; force = true, recursive = true)
    return result
end
