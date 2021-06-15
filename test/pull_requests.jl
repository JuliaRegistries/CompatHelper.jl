@testset "GitLab.MergeRequest equality" begin
    a = GitLab.MergeRequest(; id=1)
    b = GitLab.MergeRequest(; id=1)

    @test a == b
    @test isequal(a, b)
end

@testset "get_pull_requests" begin
    @testset "GitHub" begin
        api = GitForge.GitHub.GitHubAPI()
        repo = GitHub.Repo(; name="Foo", owner=GitHub.User(; login="Bar"))

        apply(gh_unique_patch) do
            prs = CompatHelper.get_pull_requests(
                api, repo, "open"; per_page=10, page_limit=1
            )
            @test !isempty(prs)
        end
    end

    @testset "GitLab" begin
        api = GitForge.GitLab.GitLabAPI()
        repo = GitLab.Project(; id=1)

        apply(gl_unique_patch) do
            prs = CompatHelper.get_pull_requests(api, repo, "opened")
            @test !isempty(prs)
        end
    end
end

@testset "exclude_pull_requests_from_forks" begin
    @testset "normal case" begin
        @testset "GitHub" begin
            origin_repo = GitHub.Repo(; id=1)
            fork_repo = GitHub.Repo(; id=2)

            pr_from_origin = GitHub.PullRequest(; head=GitHub.Head(; repo=origin_repo))
            pr_from_fork = GitHub.PullRequest(; head=GitHub.Head(; repo=fork_repo))

            result = CompatHelper.exclude_pull_requests_from_forks(
                origin_repo, [pr_from_origin, pr_from_fork]
            )

            @test length(result) == 1
            @test pr_from_origin in result
            @test !(pr_from_fork in result)
        end

        @testset "GitLab" begin
            origin_repo = GitLab.Project(; id=1)
            fork_repo = GitLab.Project(; id=2)

            pr_from_origin = GitLab.MergeRequest(; id=1, project_id=1)
            pr_from_fork = GitLab.MergeRequest(; id=1, project_id=2)

            result = CompatHelper.exclude_pull_requests_from_forks(
                origin_repo, [pr_from_origin, pr_from_fork]
            )

            @test length(result) == 1
            @test pr_from_origin in result
            @test !(pr_from_fork in result)
        end
    end

    @testset "empty case" begin
        @testset "GitHub" begin
            @test isempty(
                CompatHelper.exclude_pull_requests_from_forks(
                    GitHub.Repo(), Vector{GitHub.PullRequest}()
                ),
            )
        end

        @testset "GitLab" begin
            @test isempty(
                CompatHelper.exclude_pull_requests_from_forks(
                    GitLab.Project(), Vector{GitLab.MergeRequest}()
                )
            )
        end
    end
end

@testset "only_my_pull_requests" begin
    @testset "normal case" begin
        @testset "GitHub" begin
            foobar = "foobar"

            pr_by_foobar = GitHub.PullRequest(; user=GitHub.User(; login=foobar))
            pr_by_bizbaz = GitHub.PullRequest(; user=GitHub.User(; login="bizbaz"))

            result = CompatHelper.only_my_pull_requests(
                foobar, [pr_by_foobar, pr_by_bizbaz]
            )

            @test length(result) == 1
            @test pr_by_foobar in result
            @test !(pr_by_bizbaz in result)
        end

        @testset "GitLab" begin
            foobar = "foobar"

            pr_by_foobar = GitLab.MergeRequest(; author=GitLab.User(; username=foobar))
            pr_by_bizbaz = GitLab.MergeRequest(; author=GitLab.User(; username="bizbaz"))

            result = CompatHelper.only_my_pull_requests(
                foobar, [pr_by_foobar, pr_by_bizbaz]
            )

            @test length(result) == 1
            @test pr_by_foobar in result
            @test !(pr_by_bizbaz in result)
        end
    end

    @testset "empty case" begin
        @testset "GitHub" begin
            @test isempty(
                CompatHelper.only_my_pull_requests("foobar", Vector{GitHub.PullRequest}())
            )
        end

        @testset "GitLab" begin
            @test isempty(
                CompatHelper.only_my_pull_requests("foobar", Vector{GitLab.MergeRequest}())
            )
        end
    end
end

@testset "get_pr_titles" begin
    gh_gpr_patch = @patch function CompatHelper.get_pull_requests(
        api::GitHub.GitHubAPI, repo::GitHub.Repo, state::String
    )
        origin_repo = GitHub.Repo(; id=1)
        fork_repo = GitHub.Repo(; id=2)

        pr_from_origin = GitHub.PullRequest(;
            head=GitHub.Head(; repo=origin_repo),
            user=GitHub.User(; login="foobar"),
            title="title",
        )
        pr_from_origin_2 = GitHub.PullRequest(;
            head=GitHub.Head(; repo=origin_repo), user=GitHub.User(; login="bizbaz")
        )
        pr_from_fork = GitHub.PullRequest(; head=GitHub.Head(; repo=fork_repo))

        return [pr_from_origin, pr_from_origin_2, pr_from_fork]
    end

    @testset "GitHub" begin
        api = GitForge.GitHub.GitHubAPI()
        repo = GitHub.Repo(; id=1)

        apply(gh_gpr_patch) do
            prs = CompatHelper.get_pr_titles(api, repo, "foobar")
            @test !isempty(prs)
            @test prs[1] == "title"
        end
    end

    gl_gpr_patch = @patch function CompatHelper.get_pull_requests(
        api::GitLab.GitLabAPI, repo::GitLab.Project, state::String
    )
        origin_repo = GitLab.Project(; id=1)

        pr_from_origin = GitLab.MergeRequest(;
            project_id=1,
            author=GitLab.User(; username="foobar"),
            title="title",
        )
        pr_from_origin_2 = GitLab.MergeRequest(;
            project_id=1, author=GitLab.User(; username="bizbaz")
        )
        pr_from_fork = GitLab.MergeRequest(; project_id=2)

        return [pr_from_origin, pr_from_origin_2, pr_from_fork]
    end

    @testset "GitLab" begin
        api = GitForge.GitLab.GitLabAPI()
        repo = GitLab.Project(; id=1)

        apply(gl_gpr_patch) do
            prs = CompatHelper.get_pr_titles(api, repo, "foobar")
            @test !isempty(prs)
            @test prs[1] == "title"
        end
    end

end
