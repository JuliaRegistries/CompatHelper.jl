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

@testset "`version =` line in the workflow file" begin
    root_directory = dirname(dirname(@__FILE__))
    project_file = joinpath(root_directory, "Project.toml")
    version = Base.VersionNumber(TOML.parsefile(project_file)["version"])
    major_version = version.major
    @test major_version >= 1
    workflow_dir = joinpath(root_directory, ".github", "workflows")
    workflow_filename = joinpath(workflow_dir, "CompatHelper.yml")
    workflow_filecontents = read(workflow_filename, String)
    @test occursin(Regex("\\sversion = \"$(major_version)\"\n"), workflow_filecontents)
end

include("patches.jl")

@testset "CompatHelper.jl" begin
    include(joinpath("utilities", "ci.jl"))
    include(joinpath("utilities", "ssh.jl"))
    include(joinpath("utilities", "utilities.jl"))

    include("dependencies.jl")
    include("exceptions.jl")
    include("pull_requests.jl")
end
