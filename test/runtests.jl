using Aqua
using Base64
using CompatHelper
using GitForge
using GitForge: GitHub, GitLab
using Mocking
using SHA
using Test
using TOML


Mocking.activate()
Aqua.test_all(CompatHelper; ambiguities=false)

include("patches.jl")

@testset "CompatHelper.jl" begin
    include(joinpath("utilities", "ci.jl"))
    include(joinpath("utilities", "ssh.jl"))
    include(joinpath("utilities", "utilities.jl"))

    include("pull_requests.jl")
end
