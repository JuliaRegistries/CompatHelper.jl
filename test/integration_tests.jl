# You should set up a Git repo with an example Julia package for the integration tests.
# You should create a bot user GitHub account, and give the bot user GitHub account push access to the testing repo.
# You should generate a personal access token (PAT) for the bot user GitHub account.
# You should add the PAT as an encrypted Travis CI environment variable named `BCBI_TEST_USER_GITHUB_TOKEN`.
# You should generate an SSH deploy key. Upload the public key as a deploy key for the testing repo.
# You should make the private key an encrypted Travis CI environment variable named `COMPATHELPER_PRIV`. Probably you will want to Base64-encode it.

@testset "GitHub Integration Test" begin
    const GLOBAL_PR_TITLE_PREFIX = Random.randstring(8)
    const COMPATHELPER_INTEGRATION_TEST_REPO = ENV["COMPATHELPER_INTEGRATION_TEST_REPO"]
    const TEST_USER_GITHUB_TOKEN = ENV["BCBI_TEST_USER_GITHUB_TOKEN"]

    auth = CompatHelper.api_retry(() -> GitHub.authenticate(TEST_USER_GITHUB_TOKEN))
    whoami = username(auth)

    repo_url_without_auth = "https://github.com/$(COMPATHELPER_INTEGRATION_TEST_REPO)"
    repo_url_with_auth = "https://$(whoami):$(TEST_USER_GITHUB_TOKEN)@github.com/$(COMPATHELPER_INTEGRATION_TEST_REPO)"

    repo = GitHub.repo(COMPATHELPER_INTEGRATION_TEST_REPO; auth=auth)
    api = GitHub.GitHubWebAPI(HTTP.URI("https://api.github.com"))

    @test success(`git --version`)
    delete_old_pull_request_branches(repo_url_with_auth, Dates.Hour(3))

    # Setup variables used in CompatHelper.main()
    env = Dict(
        "GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
        "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN,
    )
    ci_cfg = CompatHelper.GitHubActions(
        whoami, "41898282+github-actions[bot]@users.noreply.github.com"
    )

    @testset "master_1" begin
        with_master_branch(templates("master_1"), "master"; repo_url=repo_url_with_auth) do master_1
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-1c] ",
                    master_branch=master_1,
                    entry_type=KeepEntry()
                )
            end
        end
    end

    @testset "master_2" begin
        with_master_branch(templates("master_2"), "master"; repo_url=repo_url_with_auth) do master_2
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-2c] ",
                    master_branch=master_2,
                    entry_type=KeepEntry()
                )
            end
        end
    end

    @testset "master_3" begin
        with_master_branch(templates("master_3"), "master"; repo_url=repo_url_with_auth) do master_3
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-3a] ",
                    master_branch=master_3,
                    entry_type=DropEntry()
                )

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-3b] ",
                    master_branch=master_3,
                    entry_type=KeepEntry()
                )

                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-3c] ",
                    master_branch=master_3,
                    entry_type=KeepEntry()
                )
            end
        end
    end

    @testset "master_4" begin
        with_master_branch(templates("master_4"), "master"; repo_url=repo_url_with_auth) do master_4
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-4c] ",
                    master_branch=master_4,
                    entry_type=KeepEntry()
                )
            end
        end
    end

    @testset "master_5" begin
        with_master_branch(templates("master_5"), "master"; repo_url=repo_url_with_auth) do master_5
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-5a] ",
                    master_branch=master_5,
                    entry_type=DropEntry()
                )
            end
        end
    end

    @testset "master_6" begin
        with_master_branch(templates("master_6"), "master"; repo_url=repo_url_with_auth) do master_6
            withenv(env...) do
                CompatHelper.main(
                    ENV,
                    ci_cfg;
                    pr_title_prefix="$(GLOBAL_PR_TITLE_PREFIX) [test-1c] ",
                    master_branch=master_6,
                    entry_type=KeepEntry(),
                    subdirs=["subdir_1", "subdir_2"],
                )
            end
        end
    end

    @testset "master_7" begin
        with_master_branch(templates("master_7"), "master"; repo_url=repo_url_with_auth) do master_7
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
 end
