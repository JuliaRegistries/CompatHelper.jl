Test.@testset "assert.jl" begin
    Test.@test_nowarn CompatHelper.always_assert(true)
    Test.@test CompatHelper.always_assert(true) isa Nothing
    Test.@test CompatHelper.always_assert(true) == nothing
    Test.@test Test.@test_nowarn CompatHelper.always_assert(true) isa Nothing
    Test.@test Test.@test_nowarn CompatHelper.always_assert(true) == nothing
    Test.@test_throws CompatHelper.AlwaysAssertionError CompatHelper.always_assert(false)
end

Test.@testset "ci_service.jl" begin
    withenv("GITHUB_REPOSITORY" => "foo/bar") do
        Test.@test CompatHelper.auto_detect_ci_service() isa CompatHelper.CIService
        Test.@test CompatHelper.auto_detect_ci_service() isa CompatHelper.GitHubActions
        Test.@test_throws ArgumentError CompatHelper.main(; keep_existing_compat = false, drop_existing_compat = false)
    end
    withenv("GITHUB_REPOSITORY" => nothing) do
        Test.@test_throws ErrorException CompatHelper.auto_detect_ci_service()
    end
end

Test.@testset "git.jl" begin
    Test.@test CompatHelper.git_decide_master_branch(CompatHelper.DefaultBranch(), "  abcdefg  ") == "abcdefg"
    Test.@test CompatHelper.git_decide_master_branch(" abc ", " xyz ") == "abc"
end

Test.@testset "new_versions.jl" begin
    Test.@test_throws ArgumentError CompatHelper.old_compat_to_new_compat("", "", :abc)
end
