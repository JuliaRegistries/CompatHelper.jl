@testset "GitLab.MergeRequest equality" begin
    a = GitLab.MergeRequest(id=1)
    b = GitLab.MergeRequest(id=1)

    @test a == b
    @test isequal(a, b)
end

@testset "get_pull_requests" begin
    @testset "GitHub" begin
        api = GitForge.GitHub.GitHubAPI()
        repo = GitHub.Repo(name="Foo", owner=GitHub.User(login="Bar"))

        apply(gh_unique) do
            prs = CompatHelper.get_pull_requests(api, repo, "open"; per_page=10, page_limit=1)
            @test !isempty(prs)
        end
    end

    @testset "GitLab" begin
        api = GitForge.GitLab.GitLabAPI()
        repo = GitLab.Project(id=1)

        apply(gl_unique) do
            prs = CompatHelper.get_pull_requests(api, repo, "opened")
            @test !isempty(prs)
        end
    end
end
