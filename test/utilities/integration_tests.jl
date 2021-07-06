function _cleanup_old_branches()
    DELETE_OLDER_THAN_HOURS = 3
    branches = String(read(`git branch -r`))  # Get all remote branches
    branches = strip.(split(branches, "\n "))  # Convert string into an array of branch names

    for branch in branches
        # Check if there is a commit within the last 3 hours
        # If there is, is_old will have the commit information
        # If there has not been, it will be empty
        is_old = String(read(`git log -1 --since='$(DELETE_OLDER_THAN_HOURS) hours' -s $(branch)`))

        if isempty(is_old)
            run(`git branch -d origin $(branch)`)  # Delete the branch on origin
        end
    end
end

function _generate_branch_name(name::AbstractString)
    timestamp = string(now())
    timestamp = replace(timestamp, ':' => '.')  # Git branches cannot have colons in them
    b = "integration/$(timestamp)/$(rand(UInt32))/$(name)"

    return b
end

function templates(parts...)
    test_directory = abspath(joinpath(@__DIR__, ".."))
    templates_directory = joinpath(test_directory, "templates")
    result = joinpath(templates_directory, parts...)

    return result
end

function with_master_branch(
    f::Function, path_to_content::AbstractString, repo_url::AbstractString, parent_branch::AbstractString
)
    b = generate_branch("master", path_to_content, repo_url, parent_branch)
    return f(b)
end

function generate_branch(
    name::AbstractString,
    path_to_content::AbstractString,
    repo_url::AbstractString,
    parent_branch::AbstractString="master"
)
    b = _generate_branch_name(name)
    git_repo_dir = with_cloned_repo(repo_url)

    cd(git_repo_dir) do
        CompatHelper.git_checkout(parent_branch)
        CompatHelper.git_branch(b; checkout=true)
        empty_git_repo(git_repo_dir)

        for x in readdir(path_to_content)
            src = joinpath(path_to_content, x)
            dst = joinpath(git_repo_dir, x)
            rm(dst; force=true, recursive=true)
            cp(src, dst; force=true)
        end

        CompatHelper.api_retry(() -> CompatHelper.git_add())
        CompatHelper.api_retry(() -> CompatHelper.git_commit("Automatic commit - CompatHelper integration tests"))
        CompatHelper.api_retry(() -> CompatHelper.git_push("origin", b))

        rm(git_repo_dir; force=true, recursive=true)
    end

    return b
end

function empty_git_repo(git_repo_dir::AbstractString)
    cd(git_repo_dir) do
        for x in readdir(git_repo_dir)
            if x != ".git"
                path = joinpath(git_repo_dir, x)
                rm(path; force=true, recursive=true)
            end
        end
    end

    return nothing
end

function with_cloned_repo(repo_url)
    git_repo_dir = joinpath(mktempdir(), CompatHelper.LOCAL_REPO_NAME)
    CompatHelper.api_retry(() -> CompatHelper.git_clone(repo_url, git_repo_dir))

    return git_repo_dir
end
