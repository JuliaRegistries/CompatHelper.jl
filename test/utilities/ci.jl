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

@testset "set_git_identity" begin
    function read_git_config()
        try
            name = strip(read(`git config user.name`, String))
            email = strip(read(`git config user.email`, String))

            return name, email
        catch
            return "", ""
        end
    end

    original = CompatHelper.GitHubActions(read_git_config()...)
    config = CompatHelper.GitHubActions()

    try
        CompatHelper.set_git_identity(config)

        name, email = read_git_config()

        @test name == config.username
        @test email == config.email
    finally
        CompatHelper.set_git_identity(original)
    end
end
