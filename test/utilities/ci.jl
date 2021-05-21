@testset "auto_detect_ci_service" begin
    @testset "env var present" begin
        withenv(
            "GITHUB_REPOSITORY" => "true"
        ) do
            expected = CompatHelper.GitHubActions()

            @test CompatHelper.auto_detect_ci_service() == expected
        end
    end

    @testset "env var dne" begin
        withenv(
            "GITHUB_REPOSITORY" => "foobar"
        ) do
            delete!(ENV, "GITHUB_REPOSITORY")
            @test_throws CompatHelper.UnableToDetectCIService CompatHelper.auto_detect_ci_service()
        end
    end
end
