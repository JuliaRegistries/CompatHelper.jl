using CompatHelper: CompatHelper
using Test: Test, @test, @testset, @test_throws

using Aqua: Aqua
using Base64: Base64
using GitForge: GitForge, GitHub, GitLab
using Mocking: Mocking, @patch, apply
using Pkg: Pkg
using Random: Random
using SHA: SHA
using TOML: TOML
using UUIDs: UUIDs, UUID

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
    @test length(findall(r"version[\s]*?=", workflow_filecontents)) == 1
end

include("patches.jl")

@testset "CompatHelper.jl" begin
    include(joinpath("utilities", "ci.jl"))
    include(joinpath("utilities", "git.jl"))
    include(joinpath("utilities", "new_versions.jl"))
    include(joinpath("utilities", "ssh.jl"))
    include(joinpath("utilities", "types.jl"))
    include(joinpath("utilities", "utilities.jl"))

    include("dependencies.jl")
    include("exceptions.jl")
    include("pull_requests.jl")
end
