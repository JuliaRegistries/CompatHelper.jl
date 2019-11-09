function _git_user_name_is_set()::Bool
    result = try
        success(`git config user.name`)
    catch
        false
    end
    return result
end

function _git_user_email_is_set()::Bool
    result = try
        success(`git config user.name`)
    catch
        false
    end
    return result
end

function set_git_identity(ci_cfg::GitHubActions)
    if !_git_user_name_is_set()
        try
            run(`git config user.name 'github-actions[bot]'`)
        catch
        end
    end
    if !_git_user_email_is_set()
        try
            run(`git config user.email '41898282+github-actions[bot]@users.noreply.github.com'`)
        catch
        end
    end
    return nothing
end

function auto_detect_ci_service(; env::AbstractDict = ENV)
    if haskey(env, "GITHUB_REPOSITORY")
        return GitHubActions()
    else
         error("Could not detect CI service")
    end
end

function github_repository(ci_cfg::GitHubActions; env::AbstractDict = ENV)
    result = env["GITHUB_REPOSITORY"]::String
    return result
end

function github_token(ci_cfg::GitHubActions; env::AbstractDict = ENV)
    result = env["GITHUB_TOKEN"]::String
    return result
end

function get_my_username(ci_cfg::GitHubActions; auth = nothing, env::AbstractDict = ENV)
    return "github-actions[bot]"
end
