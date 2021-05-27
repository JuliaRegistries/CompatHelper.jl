module CompatHelper

using Base64
using GitForge
using GitForge: GitHub, GitLab
using Mocking


const PRVIATE_SSH_ENVVAR = "COMPATHELPER_PRIV"

include(joinpath("utilities", "ci.jl"))
include(joinpath("utilities", "ssh.jl"))
include(joinpath("utilities", "utilities.jl"))

include("exceptions.jl")
include("pull_requests.jl")

end # module
