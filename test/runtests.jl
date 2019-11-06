using CompatHelper
using Pkg
using Test

registries_1 = Pkg.Types.RegistrySpec[Pkg.RegistrySpec(name = "General",
                                                       uuid = "23338594-aafe-5451-b93e-139f81909106",
                                                       url = "https://github.com/JuliaRegistries/General.git")]

registries_2 = Pkg.Types.RegistrySpec[Pkg.RegistrySpec(name = "General",
                                                       uuid = "23338594-aafe-5451-b93e-139f81909106",
                                                       url = "https://github.com/JuliaRegistries/General.git"),
                                      Pkg.RegistrySpec(name = "BioJuliaRegistry",
                                                       uuid = "ccbd2cc2-2954-11e9-1ccf-f3e7900901ca",
                                                       url = "https://github.com/BioJulia/BioJuliaRegistry.git")]

@testset "CompatHelper.jl" begin
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
end
