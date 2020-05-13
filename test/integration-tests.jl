# You should set up a Git repo with an example Julia package for the integration tests.
# You should create a bot user GitHub account, and give the bot user GitHub account push access to the testing repo.
# You should generate a personal access token (PAT) for the bot user GitHub account.
# You should add the PAT as an encrypted Travis CI environment variable named `BCBI_TEST_USER_GITHUB_TOKEN`.
# You should generate an SSH deploy key. Upload the public key as a deploy key for the testing repo.
# You should make the private key an encrypted Travis CI environment variable named `COMPATHELPER_PRIV`. Probably you will want to Base64-encode it.

COMPATHELPER_INTEGRATION_TEST_REPO = ENV["COMPATHELPER_INTEGRATION_TEST_REPO"]::String
TEST_USER_GITHUB_TOKEN = ENV["BCBI_TEST_USER_GITHUB_TOKEN"]::String
auth = GitHub.authenticate(TEST_USER_GITHUB_TOKEN)
whoami = username(auth)
repo_url_without_auth = "https://github.com/$(COMPATHELPER_INTEGRATION_TEST_REPO)"
repo_url_with_auth = "https://$(whoami):$(TEST_USER_GITHUB_TOKEN)@github.com/$(COMPATHELPER_INTEGRATION_TEST_REPO)"
repo = GitHub.repo(COMPATHELPER_INTEGRATION_TEST_REPO; auth = auth)
Test.@test success(`git --version`)
@info("Authenticated to GitHub as \"$(whoami)\"")

delete_stale_branches(repo_url_with_auth)

with_master_branch(templates("master_1"), "master"; repo_url = repo_url_with_auth) do master_1
    withenv("GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
            "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN) do
        precommit_hook = () -> ()
        env = ENV
        ci_cfg = CompatHelper.GitHubActions(whoami)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-1c] ",
                          master_branch = master_1,
                          keep_existing_compat = true,
                          drop_existing_compat = true)
    end
end

with_master_branch(templates("master_2"), "master"; repo_url = repo_url_with_auth) do master_2
    withenv("GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
            "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN) do
        precommit_hook = () -> ()
        env = ENV
        ci_cfg = CompatHelper.GitHubActions(whoami)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-2c] ",
                          master_branch = master_2,
                          keep_existing_compat = true,
                          drop_existing_compat = true)
    end
end

with_master_branch(templates("master_3"), "master"; repo_url = repo_url_with_auth) do master_3
    withenv("GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
            "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN) do
        precommit_hook = () -> ()
        env = ENV
        ci_cfg = CompatHelper.GitHubActions(whoami)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-3a] ",
                          master_branch = master_3,
                          keep_existing_compat = false,
                          drop_existing_compat = true)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-3b] ",
                          master_branch = master_3,
                          keep_existing_compat = true,
                          drop_existing_compat = false)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-3c] ",
                          master_branch = master_3,
                          keep_existing_compat = true,
                          drop_existing_compat = true)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-3c] ",
                          master_branch = master_3,
                          keep_existing_compat = true,
                          drop_existing_compat = true)
    end
end

with_master_branch(templates("master_4"), "master"; repo_url = repo_url_with_auth) do master_4
    withenv("GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
            "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN) do
        precommit_hook = () -> ()
        env = ENV
        ci_cfg = CompatHelper.GitHubActions(whoami)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-4c] ",
                          master_branch = master_4,
                          keep_existing_compat = true,
                          drop_existing_compat = true)
    end
end

with_master_branch(templates("master_5"), "master"; repo_url = repo_url_with_auth) do master_5
    withenv("GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
            "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN) do
        precommit_hook = (; registries) -> CompatHelper.update_manifests(;
                                                                         delete_old_manifest = true,
                                                                         registries = registries)
        env = ENV
        ci_cfg = CompatHelper.GitHubActions(whoami)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-5a] ",
                          master_branch = master_5,
                          keep_existing_compat = false,
                          drop_existing_compat = true)
    end
end

# Same as master_1 and master_5, but in sub-directories
with_master_branch(templates("master_6"), "master"; repo_url = repo_url_with_auth) do master_6
    withenv("GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
            "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN) do
        precommit_hook = () -> ()
        env = ENV
        ci_cfg = CompatHelper.GitHubActions(whoami)
        CompatHelper.main(precommit_hook, env, ci_cfg;
                          pr_title_prefix = "[test-1c] ",
                          master_branch = master_6,
                          keep_existing_compat = true,
                          drop_existing_compat = true,
                          subdirs = ["subdir_1", "subdir_2"])
    end
end

all_prs = CompatHelper.get_all_pull_requests(repo, "open";
                                             auth = auth,
                                             per_page = 3,
                                             page_limit = 3)
