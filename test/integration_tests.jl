# You should set up a Git repo with an example Julia package for the integration tests.
# You should create a bot user GitHub account, and give the bot user GitHub account push access to the testing repo.
# You should generate a personal access token (PAT) for the bot user GitHub account.
# You should add the PAT as an encrypted Travis CI environment variable named `BCBI_TEST_USER_GITHUB_TOKEN`.
# You should generate an SSH deploy key. Upload the public key as a deploy key for the testing repo.
# You should make the private key an encrypted Travis CI environment variable named `COMPATHELPER_PRIV`. Probably you will want to Base64-encode it.
const GLOBAL_PR_TITLE_PREFIX = Random.randstring(8)
const GITHUB = "GITHUB"
const GITLAB = "GITLAB"

function get_api(service_name, personal_access_token)
    if service_name == GITHUB
        token = GitHub.Token(personal_access_token)
        return GitHub.GitHubAPI(; token=token)
    elseif service_name == GITLAB
        token = GitLab.PersonalAccessToken(personal_access_token)
        return GitLab.GitLabAPI(; token=token)
    end
end

function ci_config(service_name)
    if service_name == GITHUB
        return CompatHelper.GitHubActions()
    elseif service_name == GITLAB
        return CompatHelper.GitLabCI()
    end
end

function get_url(service, user, personal_access_token, test_repo)
    login = if service == GITHUB
        user.login
    elseif service == GITLAB
        user.username
    end

    return "https://$(login):$(personal_access_token)@$(lowercase(service)).com/$(test_repo)"
end

function run_integration_tests(
    url::AbstractString,
    env::AbstractDict,
    ci_cfg::CompatHelper.CIService
)
    @testset "master_1" begin
        with_master_branch(templates("master_1"), url, "master") do master_1
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-1c] ",
                    master_branch=master_1,
                    entry_type=KeepEntry(),
                )
            end
        end
    end

    @testset "master_2" begin
        with_master_branch(templates("master_2"), url, "master") do master_2
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-2c] ",
                    master_branch=master_2,
                    entry_type=KeepEntry(),
                )
            end
        end
    end

    @testset "master_3" begin
        with_master_branch(templates("master_3"), url, "master") do master_3
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-3a] ",
                    master_branch=master_3,
                    entry_type=DropEntry(),
                )

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-3b] ",
                    master_branch=master_3,
                    entry_type=KeepEntry(),
                )

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-3c] ",
                    master_branch=master_3,
                    entry_type=KeepEntry(),
                )
            end
        end
    end

    @testset "master_4" begin
        with_master_branch(templates("master_4"), url, "master") do master_4
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-4c] ",
                    master_branch=master_4,
                    entry_type=KeepEntry(),
                )
            end
        end
    end

    @testset "master_5" begin
        with_master_branch(templates("master_5"), url, "master") do master_5
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-5a] ",
                    master_branch=master_5,
                    entry_type=DropEntry(),
                )
            end
        end
    end

    @testset "master_6" begin
        with_master_branch(templates("master_6"), url, "master") do master_6
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-6c] ",
                    master_branch=master_6,
                    entry_type=KeepEntry(),
                    subdirs=["subdir_1", "subdir_2"],
                )
            end
        end
    end

    @testset "master_7" begin
        with_master_branch(templates("master_7"), url, "master") do master_7
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-7a] ",
                    master_branch=master_7,
                    entry_type=DropEntry(),
                    bump_compat_containing_equality_specifier=false,
                )

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-7b] ",
                    master_branch=master_7,
                    entry_type=DropEntry(),
                    bump_compat_containing_equality_specifier=true,
                )
            end
        end
    end

    _cleanup_old_branches(url)
end

@testset "$(service)" for service in [GITHUB, GITLAB]
    personal_access_token = ENV["INTEGRATION_PAT_$(service)"]
    test_repo = ENV["INTEGRATION_TEST_REPO_$(service)"]

    api = get_api(service, personal_access_token)
    user, _ = GitForge.get_user(api)
    repo, _ = GitForge.get_repo(api, test_repo)

    url = get_url(service, user, personal_access_token, test_repo)

    env = Dict(
        "$(service)_REPOSITORY" => test_repo,
        "$(service)_TOKEN" => personal_access_token,
        "CI_PROJECT_PATH" => "InveniaBot/compathelper_integration_test_repo.jl"
    )

    ci_cfg = ci_config(service)
    run_integration_tests(url, env, ci_cfg)
end
