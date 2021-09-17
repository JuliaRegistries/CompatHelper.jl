@testset "main.jl" begin
    @testset "unknown ci config" begin
        struct MockCI <: CompatHelper.CIService end

        @test_throws ErrorException("Unknown CI Config: MockCI") CompatHelper.main(
            ENV, MockCI()
        )
    end

    @testset "no pr GitHub" begin
        tmpdir = mktempdir()

        cd(tmpdir) do
            patches = [
                git_clone_patch,
                project_toml_patch,
                clone_all_registries_patch,
                rm_patch,
                pr_titles_mock,
                git_push_patch,
                gh_pr_patch,
                make_clone_https_patch(tmpdir),
                decode_pkey_patch,
                gh_get_repo_patch,
                cd_patch,
                git_gmb_patch,
                git_checkout_patch,
            ]
            apply(patches) do
                withenv(
                    "GITHUB_REPOSITORY" => "CompatHelper.jl", "GITHUB_TOKEN" => "token"
                ) do
                    prs = CompatHelper.main()
                    @test length(prs) == 0
                end
            end
        end
    end

    @testset "successful run GitHub" begin
        tmpdir = mktempdir()

        cd(tmpdir) do
            patches = [
                git_clone_patch,
                project_toml_patch,
                clone_all_registries_patch,
                rm_patch,
                pr_titles_mock,
                git_push_patch,
                gh_pr_patch,
                make_clone_https_patch(tmpdir),
                decode_pkey_patch,
                gh_get_repo_patch,
                cd_patch,
                git_gmb_patch,
                git_checkout_patch,
                gh_make_pr_patch,
            ]
            apply(patches) do
                withenv(
                    "GITHUB_REPOSITORY" => "CompatHelper.jl", "GITHUB_TOKEN" => "token"
                ) do
                    prs = CompatHelper.main()
                    @test length(prs) == 1
                    @test prs[1] isa GitHub.PullRequest
                end
            end
        end
    end

    @testset "successful run GitLab" begin
        mktempdir() do tmpdir
            cd(tmpdir) do
                patches = [
                    git_clone_patch,
                    project_toml_patch,
                    clone_all_registries_patch,
                    rm_patch,
                    pr_titles_mock,
                    git_push_patch,
                    gl_pr_patch,
                    make_clone_https_patch(tmpdir),
                    decode_pkey_patch,
                    gl_get_repo_patch,
                    cd_patch,
                    gl_make_pr_patch,
                ]

                apply(patches) do
                    withenv(
                        "GITLAB_CI" => "true",
                        "CI_PROJECT_PATH" => "CompatHelper.jl",
                        "GITLAB_TOKEN" => "token",
                        "GITHUB_REPOSITORY" => "false",
                    ) do
                        delete!(ENV, "GITHUB_REPOSITORY")
                        prs = CompatHelper.main()
                        @test length(prs) == 1
                        @test prs[1] isa GitLab.MergeRequest
                    end
                end
            end
        end
    end
end
