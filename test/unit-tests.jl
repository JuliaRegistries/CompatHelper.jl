include("utils.jl")

@testset "assert.jl" begin
    @test_nowarn CompatHelper.always_assert(true)
    @test CompatHelper.always_assert(true) isa Nothing
    @test CompatHelper.always_assert(true) == nothing
    @test @test_nowarn CompatHelper.always_assert(true) isa Nothing
    @test @test_nowarn CompatHelper.always_assert(true) == nothing
    @test_throws CompatHelper.AlwaysAssertionError CompatHelper.always_assert(false)
end

@testset "ci_service.jl" begin
    withenv("GITHUB_REPOSITORY" => "foo/bar") do
        @test CompatHelper.auto_detect_ci_service() isa CompatHelper.CIService
        @test CompatHelper.auto_detect_ci_service() isa CompatHelper.GitHubActions
        @test_throws ArgumentError CompatHelper.main(; keep_existing_compat = false, drop_existing_compat = false)
    end
    withenv("GITHUB_REPOSITORY" => nothing) do
        @test_throws ErrorException CompatHelper.auto_detect_ci_service()
    end
end

@testset "new_versions.jl" begin
    @test_throws ArgumentError CompatHelper.old_compat_to_new_compat("", "", :abc)
end
