get_random_string() = string(utc_to_string(now_localzone()), "-", rand(UInt32))

function add_compat_section!(project::Dict)
    if !haskey(project, "compat")
        project["compat"] = Dict{Any, Any}()
    end
    return project
end

function generate_pr_title_parenthetical(
    keep_or_drop::Symbol,
    parenthetical_in_pr_title::Bool
)
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
