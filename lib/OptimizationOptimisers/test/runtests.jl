using OptimizationOptimisers, Optimization, ForwardDiff
using Test
using Zygote

@testset "OptimizationOptimisers.jl" begin
    rosenbrock(x, p) = (p[1] - x[1])^2 + p[2] * (x[2] - x[1]^2)^2
    x0 = zeros(2)
    _p = [1.0, 100.0]
    l1 = rosenbrock(x0, _p)

    optprob = OptimizationFunction(rosenbrock, Optimization.AutoForwardDiff())

    prob = OptimizationProblem(optprob, x0, _p)

    sol = Optimization.solve(prob, Optimisers.ADAM(0.1), maxiters = 1000)
    @test 10 * sol.objective < l1

    prob = OptimizationProblem(optprob, x0, _p)
    sol = solve(prob, Optimisers.ADAM(), maxiters = 1000, progress = false)
    @test 10 * sol.objective < l1

    x0 = 2 * ones(ComplexF64, 2)
    _p = ones(2)
    sumfunc(x0, _p) = sum(abs2, (x0 - _p))
    l1 = sumfunc(x0, _p)

    optprob = OptimizationFunction(sumfunc, Optimization.AutoZygote())

    prob = OptimizationProblem(optprob, x0, _p)

    sol = solve(prob, Optimisers.ADAM(), maxiters = 1000)
    @test 10 * sol.objective < l1

    @testset "cache" begin
        objective(x, p) = (p[1] - x[1])^2
        x0 = zeros(1)
        p = [1.0]

        prob = OptimizationProblem(objective, x0, p)
        cache = Optimization.init(prob, Optimisers.ADAM())
        sol = Optimization.solve!(cache)
        @test sol.u ≈ [1.0]

        cache = Optimization.reinit!(cache; p = [2.0])
        sol = Optimization.solve!(cache)
        @test sol.u ≈ [2.0]
    end
end
