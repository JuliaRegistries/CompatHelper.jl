@testset "main.jl" begin
    @testset "unknown ci config" begin
        struct MockCI <: CompatHelper.CIService end
        CompatHelper.api_hostname(::MockCI) = ""
        CompatHelper.clone_hostname(::MockCI) = ""

        @test_throws ErrorException("Unknown CI Config") CompatHelper.main(ENV, MockCI())
    end

    @testset "successful run" begin
        mktempdir() do tmpdir
            cd(tmpdir)
            patches = [
                git_clone_patch, project_toml_patch, clone_all_registries_patch, rm_patch,
                pr_titles_mock, git_push_patch, gh_pr_patch, make_clone_https_patch(tmpdir),
                decode_pkey_patch, gh_get_repo_patch
            ]

            apply(patches) do
                withenv(
                    "GITHUB_REPOSITORY" => "CompatHelper.jl",
                    "GITHUB_TOKEN" => "token",
                ) do
                    CompatHelper.main()
                end
            end
        end
    end
end
