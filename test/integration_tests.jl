# You should set up a Git repo with an example Julia package for the integration tests.
# You should create a bot user GitHub account, and give the bot user GitHub account push access to the testing repo.
# You should generate a personal access token (PAT) for the bot user GitHub account.
# You should add the PAT as an encrypted Travis CI environment variable named `BCBI_TEST_USER_GITHUB_TOKEN`.
# You should generate an SSH deploy key. Upload the public key as a deploy key for the testing repo.
# You should make the private key an encrypted Travis CI environment variable named `COMPATHELPER_PRIV`. Probably you will want to Base64-encode it.
const GLOBAL_PR_TITLE_PREFIX = Random.randstring(8)
const GITHUB = "GITHUB"
const GITLAB = "GITLAB"

function run_integration_tests(
    url::AbstractString, env::AbstractDict, ci_cfg::CompatHelper.CIService
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

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

                sleep(1)  # Prevent hitting the GH Secondary Rate Limits

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-3b] ",
                    master_branch=master_3,
                    entry_type=KeepEntry(),
                )

                sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

                sleep(1)  # Prevent hitting the GH Secondary Rate Limits

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

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

    @testset "master_8" begin
        with_master_branch(templates("master_8"), url, "master") do master_8
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-8a] ",
                    master_branch=master_8,
                    entry_type=DropEntry(),
                    use_existing_registries=true,
                )
            end
        end
    end

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

    @testset "master_9" begin
        with_master_branch(templates("master_9"), url, "master") do master_9
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-9c] ",
                    master_branch=master_9,
                    entry_type=KeepEntry(),
                )
            end
        end
    end

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

    @testset "master_10" begin
        with_master_branch(templates("master_10"), url, "master") do master_10
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-10a] ",
                    master_branch=master_10,
                    entry_type=DropEntry(),
                )

                sleep(1)  # Prevent hitting the GH Secondary Rate Limits

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-10b] ",
                    master_branch=master_10,
                    entry_type=KeepEntry(),
                )

                sleep(1)  # Prevent hitting the GH Secondary Rate Limits

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-10c] ",
                    master_branch=master_10,
                    entry_type=KeepEntry(),
                )
            end
        end
    end

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

    @testset "master_11" begin
        with_master_branch(templates("master_11"), url, "master") do master_11
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-11c] ",
                    master_branch=master_11,
                    entry_type=KeepEntry(),
                )
            end
        end
    end

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

    @testset "master_12" begin
        with_master_branch(templates("master_12"), url, "master") do master_12
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-12a] ",
                    master_branch=master_12,
                    entry_type=DropEntry(),
                )
            end
        end
    end

    sleep(1)  # Prevent hitting the GH Secondary Rate Limits

    @testset "master_13" begin
        with_master_branch(templates("master_13"), url, "master") do master_13
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-13a] ",
                    master_branch=master_13,
                    entry_type=DropEntry(),
                )
            end
        end
    end

    return _cleanup_old_branches(url)
end

@testset "$(service)" for service in [GITHUB, GITLAB]
    personal_access_token = ENV["INTEGRATION_PAT_$(service)"]
    test_repo = ENV["INTEGRATION_TEST_REPO_$(service)"]

    env = Dict(
        "$(service)_REPOSITORY" => test_repo,
        "$(service)_TOKEN" => personal_access_token,
        "CI_PROJECT_PATH" => ENV["INTEGRATION_TEST_REPO_GITLAB"],
    )

    # Otherwise auto_detect_ci_service() will think we're testing on GitHub
    if service == GITLAB
        delete!(env, "GITHUB_REPOSITORY")
        env["GITLAB_CI"] = "true"
    end

    ci_cfg = CompatHelper.auto_detect_ci_service(; env=env)
    api, repo = CompatHelper.get_api_and_repo(ci_cfg; env=env)
    url = CompatHelper.get_url_with_auth(api, ci_cfg, repo)

    run_integration_tests(url, env, ci_cfg)
end
