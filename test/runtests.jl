using CompatHelper
using GitForge
using GitForge: GitHub, GitLab
using Mocking
using Test


Mocking.activate()

include("patches.jl")

@testset "CompatHelper.jl" begin
    include("pull_requests.jl")
end
