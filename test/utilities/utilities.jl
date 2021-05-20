@testset "private_compat_helper" begin
    @testset "not-false" begin
        withenv(
            CompatHelper.PRIVATE_COMPAT_HELPER => "foobar"
        ) do
            @test CompatHelper.private_compat_helper()
        end
    end

    @testset "false" begin
        withenv(
            CompatHelper.PRIVATE_COMPAT_HELPER => "false"
        ) do
            @test !(CompatHelper.private_compat_helper())
        end
    end

    @testset "dne" begin
        withenv() do
            @test !(CompatHelper.private_compat_helper())
        end
    end
end

@testset "lower" begin
    expected = "foobar"

    @test CompatHelper.lower("FOOBAR ") == expected
end
