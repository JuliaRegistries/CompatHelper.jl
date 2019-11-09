COMPATHELPER_INTEGRATION_TEST_REPO = ENV["COMPATHELPER_INTEGRATION_TEST_REPO"]::String
TEST_USER_GITHUB_TOKEN = ENV["BCBI_TEST_USER_GITHUB_TOKEN"]::String
auth = GitHub.authenticate(TEST_USER_GITHUB_TOKEN)
whoami = username(auth)
repo_url_without_auth = "https://github.com/$(COMPATHELPER_INTEGRATION_TEST_REPO)"
repo_url_with_auth = "https://$(whoami):$(TEST_USER_GITHUB_TOKEN)@github.com/$(COMPATHELPER_INTEGRATION_TEST_REPO)"
repo = GitHub.repo(COMPATHELPER_INTEGRATION_TEST_REPO; auth = auth)
Test.@test success(`git --version`)
@info("Authenticated to GitHub as \"$(whoami)\"")

close_all_pull_requests(repo; auth = auth, state = "open")
delete_stale_branches(repo_url_with_auth)

with_master_branch(templates("master_1"),
                   "master";
                   repo_url = repo_url_with_auth) do master_1
    withenv("GITHUB_REPOSITORY" => COMPATHELPER_INTEGRATION_TEST_REPO,
            "GITHUB_TOKEN" => TEST_USER_GITHUB_TOKEN) do
    end
end
