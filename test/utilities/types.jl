@testset "Package Base.in" begin
    p = CompatHelper.Package("Foobar", UUID(1))
    ce = CompatHelper.CompatEntry(p)

    @testset "Exists" begin
        s = Set([ce])

        @test p in s
    end

    @testset "DNE" begin
        @test !(p in Set())
    end
end
