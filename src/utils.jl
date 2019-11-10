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

function with_tmp_dir(f::Function)
    tmp_dir = mktempdir()
    atexit(() -> rm(tmp_dir; force = true, recursive = true))
    result = f(tmp_dir)
    rm(tmp_dir; force = true, recursive = true)
    return result
end
