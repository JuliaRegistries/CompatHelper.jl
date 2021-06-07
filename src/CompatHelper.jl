module CompatHelper

using Base64: Base64
using GitForge: GitForge, GitHub, GitLab
using Mocking: Mocking, @mock
using Pkg: Pkg
using TOML: TOML
using UUIDs: UUIDs, UUID

@static if Base.VERSION >= v"1.7-"
    const VersionSpec = Pkg.Versions.VersionSpec
else
    const VersionSpec = Pkg.Types.VersionSpec
end

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
