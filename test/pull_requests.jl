@testset "GitLab.MergeRequest equality" begin
    a = GitLab.MergeRequest(id = 1)
    b = GitLab.MergeRequest(id = 1)

    @test a == b
    @test isequal(a, b)
end

@testset "get_pull_requests" begin
    @testset "GitHub" begin
        api = GitForge.GitHub.GitHubAPI()
        repo = GitHub.Repo(name = "Foo", owner = GitHub.User(login = "Bar"))

        apply(gh_unique) do
            prs = CompatHelper.get_pull_requests(
                api,
                repo,
                "open";
                per_page = 10,
                page_limit = 1,
            )
            @test !isempty(prs)
        end
    end

    @testset "GitLab" begin
        api = GitForge.GitLab.GitLabAPI()
        repo = GitLab.Project(id = 1)

        apply(gl_unique) do
            prs = CompatHelper.get_pull_requests(api, repo, "opened")
            @test !isempty(prs)
        end
    end
end

@testset "exclude_pull_requests_from_forks" begin
    @testset "normal case" begin
        origin_repo = GitHub.Repo(id = 1)
        fork_repo = GitHub.Repo(id = 2)

        pr_from_origin = GitHub.PullRequest(head = GitHub.Head(repo = origin_repo))
        pr_from_fork = GitHub.PullRequest(head = GitHub.Head(repo = fork_repo))

        result =
            CompatHelper.exclude_pull_requests_from_forks(origin_repo, [pr_from_origin])

        @test length(result) == 1
        @test pr_from_origin in result
        @test !(pr_from_fork in result)
    end

    @testset "empty case" begin
        @test isempty(
            CompatHelper.exclude_pull_requests_from_forks(
                GitHub.Repo(),
                Vector{GitHub.PullRequest}(),
            ),
        )
    end
end

@testset "only_my_pull_requests" begin
    @testset "normal case" begin
        foobar = "foobar"

        pr_by_foobar = GitHub.PullRequest(user = GitHub.User(login = foobar))
        pr_by_bizbaz = GitHub.PullRequest(user = GitHub.User(login = "bizbaz"))

        result = CompatHelper.only_my_pull_requests(foobar, [pr_by_foobar, pr_by_bizbaz])

        @test length(result) == 1
        @test pr_by_foobar in result
        @test !(pr_by_bizbaz in result)
    end

    @testset "empty case" begin
        @test isempty(
            CompatHelper.only_my_pull_requests("foobar", Vector{GitHub.PullRequest}()),
        )
    end
end
