@testset "git_clone" begin
    mktempdir() do f
        local_path = joinpath(f, CompatHelper.LOCAL_REPO_NAME)
        CompatHelper.git_clone("https://github.com/JuliaRegistries/CompatHelper.jl/", local_path)

        @test !isempty(readdir(local_path))
    end
end

@testset "git_branch" begin
    master = "master"

    mktempdir() do f
        cd(f)
        run(`git init`)
        # Need to create a commit before hand, see below
        # https://stackoverflow.com/a/63480330/1327636
        run(`touch foobar.txt`)
        run(`git add .`)
        run(`git -c user.name='Foobar' -c user.email='foo@bar.org' commit -m "Message"`)
        CompatHelper.git_checkout(master)
        result = String(read((`git branch --show-current`)))

        @test contains(result, master)
    end
end

@testset "add_compat_section!" begin
    @testset "exists" begin
        d = Dict("compat"=>"foobar")
        CompatHelper.add_compat_section!(d)

        @test haskey(d, "compat")
    end

    @testset "dne" begin
        d = Dict()
        CompatHelper.add_compat_section!(d)

        @test haskey(d, "compat")
    end
end

@testset "get_project_deps" begin
    @testset "no jll" begin
        apply([git_clone, project_toml]) do
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(),
                "",
                GitHub.Repo(full_name="foobar"),
            )

            @test length(deps) == 1
        end
    end

    @testset "include_jll" begin
        apply([git_clone, project_toml]) do
            deps = CompatHelper.get_project_deps(
                GitForge.GitHub.GitHubAPI(),
                "",
                GitHub.Repo(full_name="foobar"),
                include_jll=true
            )

            @test length(deps) == 2
        end
    end
end
