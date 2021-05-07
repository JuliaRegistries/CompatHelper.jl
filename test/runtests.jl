using CompatHelper
using Test

using Base64
using Dates
using GitHub
using HTTP
using JSON
using Pkg
using Printf
using Random
using TimeZones
using TOML

const registries_1 = Pkg.RegistrySpec[Pkg.RegistrySpec(;
    name="General",
    uuid="23338594-aafe-5451-b93e-139f81909106",
    url="https://github.com/JuliaRegistries/General.git",
)]

const registries_2 = Pkg.RegistrySpec[
    Pkg.RegistrySpec(;
        name="General",
        uuid="23338594-aafe-5451-b93e-139f81909106",
        url="https://github.com/JuliaRegistries/General.git",
    ),
    Pkg.RegistrySpec(;
        name="BioJuliaRegistry",
        uuid="ccbd2cc2-2954-11e9-1ccf-f3e7900901ca",
        url="https://github.com/BioJulia/BioJuliaRegistry.git",
    ),
]

@testset "CompatHelper.jl" begin
    include("integration-test-utilities.jl")
    include("unit-tests.jl")

    COMPATHELPER_RUN_INTEGRATION_TESTS =
        get(ENV, "COMPATHELPER_RUN_INTEGRATION_TESTS", "")::String
    if COMPATHELPER_RUN_INTEGRATION_TESTS == "true"
        @testset "CompatHelper.jl integration tests" begin
            include("integration-tests.jl")
        end
    end
end
