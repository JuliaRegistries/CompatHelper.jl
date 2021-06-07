gh_unique_patch = @patch function Base.unique(
    ::GitForge.Paginator{GitForge.GitHub.PullRequest}
)
    return [GitHub.PullRequest(; id=1), GitHub.PullRequest(; id=2)]
end
gl_unique_patch = @patch function Base.unique(
    ::GitForge.Paginator{GitForge.GitLab.MergeRequest}
)
    return [GitLab.MergeRequest(; id=1), GitLab.MergeRequest(; id=2)]
end
project_toml_patch = @patch function Base.joinpath(p::AbstractString...)
    return joinpath(@__DIR__, "deps", "Project.toml")
end
git_clone_patch = @patch function CompatHelper.git_clone(
    url::AbstractString, p::AbstractString
)
    return nothing
end
mktempdir_patch = @patch Base.mktempdir(; cleanup::Bool=true) = Random.randstring()
rm_patch = @patch Base.rm(tmp_dir; force=true, recursive=true) = nothing

clone_all_registries_patch = @patch function CompatHelper.clone_all_registries(
    f::Function, registry_list::Vector{Pkg.RegistrySpec}
)
    return f([
        joinpath(@__DIR__, "deps", "registry_1"), joinpath(@__DIR__, "deps", "registry_2")
    ])
end
