module CompatHelper

using Base64
using GitForge
using GitForge: GitHub, GitLab
using Mocking
using Pkg
using Pkg: TOML
using Pkg.Types: VersionSpec
using TOML
using UUIDs

const PRIVATE_SSH_ENVVAR = "COMPATHELPER_PRIV"

include(joinpath("utilities", "utilities.jl"))
include(joinpath("utilities", "ci.jl"))
include(joinpath("utilities", "git.jl"))
include(joinpath("utilities", "ssh.jl"))
include(joinpath("utilities", "types.jl"))

include("exceptions.jl")
include("dependencies.jl")
include("pull_requests.jl")

end # module
