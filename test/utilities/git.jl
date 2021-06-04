@testset "git_clone" begin
    mktempdir() do f
        local_path = joinpath(f, CompatHelper.LOCAL_REPO_NAME)
        CompatHelper.git_clone(
            "https://github.com/JuliaRegistries/CompatHelper.jl/", local_path
        )

        @test !isempty(readdir(local_path))
    end
end

@testset "git_checkout" begin
    master = "master"

    mktempdir() do f
        cd(f)
        run(`git init`)
        # Need to create a commit before hand, see below
        # https://stackoverflow.com/a/63480330/1327636
        run(`touch foobar.txt`)
        run(`git add .`)
        run(
            `git -c user.name='$(CompatHelper.GIT_COMMIT_NAME)' -c user.email='$(CompatHelper.GIT_COMMIT_EMAIL)' commit -m "Message"`,
        )
        CompatHelper.git_checkout(master)
        result = String(read((`git branch --show-current`)))

        @test contains(result, master)
    end
end
