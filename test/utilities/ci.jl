@testset "auto_detect_ci_service" begin
    @testset "GitHub: env var present" begin
        withenv("GITHUB_REPOSITORY" => "true") do
            expected = CompatHelper.GitHubActions()

            @test CompatHelper.auto_detect_ci_service() == expected
        end
    end

    @testset "GitLab: env var present" begin
        withenv("GITLAB_CI" => "path") do
            expected = CompatHelper.GitLabCI()

            @test CompatHelper.auto_detect_ci_service() == expected
        end
    end

    @testset "env var dne" begin
        withenv("GITHUB_REPOSITORY" => "foobar", "GITLAB_CI" => "foobar") do
            delete!(ENV, "GITHUB_REPOSITORY")
            delete!(ENV, "GITLAB_CI")
            @test_throws CompatHelper.UnableToDetectCIService CompatHelper.auto_detect_ci_service()
        end
    end
end

@testset "$(func)" for func in [CompatHelper.github_repository, CompatHelper.github_token]
    value = "value"

    @testset "exists" begin
        withenv("GITHUB_REPOSITORY" => value, "GITHUB_TOKEN" => value) do
            @test func() == value
        end
    end

    @testset "dne" begin
        withenv("GITHUB_REPOSITORY" => value, "GITHUB_TOKEN" => value) do
            delete!(ENV, "GITHUB_REPOSITORY")
            delete!(ENV, "GITHUB_TOKEN")

            @test_throws KeyError func()
        end
    end
end

@testset "$(func)" for func in [CompatHelper.gitlab_repository, CompatHelper.gitlab_token]
    value = "value"

    @testset "exists" begin
        withenv("CI_PROJECT_PATH" => value, "GITLAB_TOKEN" => value) do
            @test func() == value
        end
    end

    @testset "dne" begin
        withenv("CI_PROJECT_PATH" => value, "GITLAB_TOKEN" => value) do
            delete!(ENV, "CI_PROJECT_PATH")
            delete!(ENV, "GITLAB_TOKEN")

            @test_throws KeyError func()
        end
    end
end
