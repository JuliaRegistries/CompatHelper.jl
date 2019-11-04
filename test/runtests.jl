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
    @test 1 == 1
end
