import CompatHelper
import Dates
import GitHub
import JSON
import Pkg
import Printf
import Test
import TimeZones

const timestamp_regex = r"integration\/(\d\d\d\d-\d\d-\d\d-\d\d-\d\d-\d\d-\d\d\d)\/"
const integration_regex = r"integration\/"
const compathelper_regex = r"compathelper\/"

function close_all_pull_requests(repo::GitHub.Repo;
                                 auth::GitHub.Authorization,
                                 state::String)
    all_pull_requests = CompatHelper.get_all_pull_requests(repo,
                                                           state;
                                                           auth = auth)
    for pr in all_pull_requests
        try
            GitHub.close_pull_request(repo, pr; auth = auth)
        catch
        end
    end
    return nothing
end

function delete_stale_branches(AUTOMERGE_INTEGRATION_TEST_REPO)
    with_cloned_repo(AUTOMERGE_INTEGRATION_TEST_REPO) do git_repo_dir
        cd(git_repo_dir)
        all_origin_branches = list_all_origin_branches(git_repo_dir)::Vector{String}
        for b in all_origin_branches
            if occursin(timestamp_regex, b) || occursin(integration_regex, b) || occursin(compathelper_regex, b)
                try
                    run(`git push origin --delete $(b)`)
                catch
                end
            end
        end
    end
    return nothing
end

function empty_git_repo(git_repo_dir::AbstractString)
    original_working_directory = pwd()
    cd(git_repo_dir)
    for x in readdir(git_repo_dir)
        if x != ".git"
            path = joinpath(git_repo_dir, x)
            rm(path; force = true, recursive = true)
        end
    end
    cd(original_working_directory)
    return nothing
end

function _generate_branch_name(name::AbstractString)
    sleep(0.1)
    _now = now_localzone()
    _now_utc_string = utc_to_string(_now)
    b = "integration/$(_now_utc_string)/$(rand(UInt32))/$(name)"
    sleep(0.1)
    return b
end


function generate_branch(name::AbstractString,
                         path_to_content::AbstractString,
                         parent_branch::AbstractString = "master";
                         repo_url)
    original_working_directory = pwd()
    b = _generate_branch_name(name)
    with_cloned_repo(repo_url) do git_repo_dir
        cd(git_repo_dir)
        run(`git checkout $(parent_branch)`)
        run(`git branch $(b)`)
        run(`git checkout $(b)`)
        empty_git_repo(git_repo_dir)
        for x in readdir(path_to_content)
            src = joinpath(path_to_content, x)
            dst = joinpath(git_repo_dir, x)
            rm(dst; force = true, recursive = true)
            cp(src, dst; force = true)
        end
        cd(git_repo_dir)
        try
            run(`git add -A`)
        catch
        end
        try
            run(`git commit -m "Automatic commit - CompatHelper integration tests"`)
        catch
        end
        try
            run(`git push origin $(b)`)
        catch
        end
        cd(original_working_directory)
        rm(git_repo_dir; force = true, recursive = true)
    end
    return b
end

function generate_master_branch(path_to_content::AbstractString,
                                parent_branch::AbstractString = "master";
                                repo_url)
    name = "master"
    b = generate_branch(name, path_to_content, parent_branch; repo_url = repo_url)
    return b
end

function generate_feature_branch(path_to_content::AbstractString,
                                 parent_branch::AbstractString;
                                 repo_url)
    name = "feature"
    b = generate_branch(name,
                        path_to_content,
                        parent_branch;
                        repo_url = repo_url)
    return b
end

function get_git_current_head(dir)
    original_working_directory = pwd()
    cd(dir)
    result = convert(String, strip(read(`git rev-parse HEAD`, String)))::String
    cd(original_working_directory)
    return result
end

function list_all_origin_branches(git_repo_dir)
    result = Vector{String}(undef, 0)
    original_working_directory = pwd()
    cd(git_repo_dir)
    a = try
        read(`git branch -a`, String)
    catch
        ""
    end
    b = split(strip(a), '\n')
    b_length = length(b)
    c = Vector{String}(undef, b_length)
    for i = 1:b_length
        c[i] = strip(strip(strip(b[i]), '*'))
        c[i] = first(split(c[i], "->"))
        c[i] = strip(c[i])
    end
    my_regex = r"^remotes\/origin\/(.*)$"
    for i = 1:b_length
        if occursin(my_regex, c[i])
            m = match(my_regex, c[i])
            if m[1] != "HEAD"
                push!(result, m[1])
            end
        end
    end
    cd(original_working_directory)
    return result
end

@inline now_localzone() = TimeZones.now(TimeZones.localzone())

function templates(parts...)
    this_filename = @__FILE__
    test_directory = dirname(this_filename)
    templates_directory = joinpath(test_directory, "templates")
    result = joinpath(templates_directory, parts...)
    return result
end

function username(auth::GitHub.Authorization)
    user_information = GitHub.gh_get_json(GitHub.DEFAULT_API,
                                          "/user";
                                          auth = auth)
    return user_information["login"]::String
end

@inline function utc_to_string(zdt::TimeZones.ZonedDateTime)
    zdt_as_utc = TimeZones.astimezone(zdt, TimeZones.tz"UTC")
    year = TimeZones.Year(zdt_as_utc.utc_datetime).value
    month = TimeZones.Month(zdt_as_utc.utc_datetime).value
    day = TimeZones.Day(zdt_as_utc.utc_datetime).value
    hour = TimeZones.Hour(zdt_as_utc.utc_datetime).value
    minute = TimeZones.Minute(zdt_as_utc.utc_datetime).value
    second = TimeZones.Second(zdt_as_utc.utc_datetime).value
    millisecond = TimeZones.Millisecond(zdt_as_utc.utc_datetime).value
    result = Printf.@sprintf "%04d-%02d-%02d-%02d-%02d-%02d-%03d" year month day hour minute second millisecond
    return result
end

function with_cloned_repo(f, repo_url)
    original_working_directory = pwd()
    result = with_temp_dir() do dir
        git_repo_dir = joinpath(dir, "REPO")
        cd(dir)
        try
            run(`git clone $(repo_url) REPO`)
        catch
        end
        cd(git_repo_dir)
        return f(git_repo_dir)
    end
    cd(original_working_directory)
    return result
end

function with_feature_branch(f::Function,
                             path_to_content::AbstractString,
                             parent_branch::AbstractString;
                             repo_url)
    b = generate_feature_branch(path_to_content,
                                parent_branch;
                                repo_url = repo_url)
    result = f(b)
    return result
end

function with_master_branch(f::Function,
                            path_to_content::AbstractString,
                            parent_branch::AbstractString;
                            repo_url)
    b = generate_master_branch(path_to_content,
                               parent_branch;
                               repo_url = repo_url)
    result = f(b)
    return result
end

function with_temp_dir(f)
    original_working_directory = pwd()
    tmp_dir = mktempdir()
    atexit(() -> rm(tmp_dir; force = true, recursive = true))
    cd(tmp_dir)
    result = f(tmp_dir)
    cd(original_working_directory)
    rm(tmp_dir; force = true, recursive = true)
    return result
end
