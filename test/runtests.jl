import CompatHelper
import Test

import Base64
import Dates
import GitHub
import HTTP
import JSON
import Pkg
import Printf
import Random
import TOML
import TimeZones

const registries_1 = Pkg.RegistrySpec[Pkg.RegistrySpec(name = "General",
                                                       uuid = "23338594-aafe-5451-b93e-139f81909106",
                                                       url = "https://github.com/JuliaRegistries/General.git")]

const registries_2 = Pkg.RegistrySpec[Pkg.RegistrySpec(name = "General",
                                                       uuid = "23338594-aafe-5451-b93e-139f81909106",
                                                       url = "https://github.com/JuliaRegistries/General.git"),
                                      Pkg.RegistrySpec(name = "BioJuliaRegistry",
                                                       uuid = "ccbd2cc2-2954-11e9-1ccf-f3e7900901ca",
                                                       url = "https://github.com/BioJulia/BioJuliaRegistry.git")]

include("integration-test-utilities.jl")

Test.@testset "CompatHelper.jl" begin
    Test.@testset "CompatHelper.jl unit tests" begin
        @info("Running the CompatHelper.jl unit tests")
        include("unit-tests.jl")
    end

    COMPATHELPER_RUN_INTEGRATION_TESTS = get(ENV, "COMPATHELPER_RUN_INTEGRATION_TESTS", "")::String
    if COMPATHELPER_RUN_INTEGRATION_TESTS == "true"
        Test.@testset "CompatHelper.jl integration tests" begin
            @info("Running the CompatHelper.jl integration tests")
            include("integration-tests.jl")
        end
    end
end
