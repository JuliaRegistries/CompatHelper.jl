module CompatHelper

using GitForge
using GitForge: GitHub, GitLab
using Mocking
using Pkg
using TOML
using UUIDs

include("dependencies.jl")
include("pull_requests.jl")

end # module
