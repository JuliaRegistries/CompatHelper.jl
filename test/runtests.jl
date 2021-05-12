using CompatHelper
using Test

@testset "CompatHelper.jl" begin
    @test CompatHelper.hello(1) == 2 # TODO: delete this line once we have deleted the `CompatHelper.hello` function
end
