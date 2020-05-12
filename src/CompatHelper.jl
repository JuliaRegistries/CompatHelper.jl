module CompatHelper

include("types.jl")

include("main.jl")

include("assert.jl")
include("ci_service.jl")
include("get_latest_version_from_registries.jl")
include("get_project_deps.jl")
include("git.jl")
include("new_versions.jl")
include("pull_requests.jl")
include("ssh_keys.jl")
include("stdlib.jl")
include("timestamps.jl")
include("update_manifests.jl")
include("utils.jl")
include("version_numbers.jl")

end # module
