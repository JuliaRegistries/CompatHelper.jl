using CompatHelper
using GitForge
using GitForge: GitHub, GitLab
using Mocking
using Test
using TOML


Mocking.activate()

include("patches.jl")

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

@testset "CompatHelper.jl" begin
    include("pull_requests.jl")
end
