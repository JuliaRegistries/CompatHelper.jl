@testset "has_ssh_private_key" begin
    @testset "not-false" begin
        withenv(
            CompatHelper.PRIVATE_SSH_ENVVAR => "foobar"
        ) do
            @test CompatHelper.has_ssh_private_key()
        end
    end

    @testset "false" begin
        withenv(
            CompatHelper.PRIVATE_SSH_ENVVAR => "false"
        ) do
            @test !(CompatHelper.has_ssh_private_key())
        end
    end

    @testset "dne" begin
        withenv(
            CompatHelper.PRIVATE_SSH_ENVVAR => "true"
        ) do
            delete!(ENV, CompatHelper.PRIVATE_SSH_ENVVAR)
            @test !(CompatHelper.has_ssh_private_key())
        end
    end
end

@testset "lower" begin
    expected = "foobar"

    @test CompatHelper.lower("FOOBAR ") == expected
end
