module OptimizationFlux

using Reexport, Printf, ProgressLogging
@reexport using Flux, Optimization
using Optimization.SciMLBase

SciMLBase.supports_opt_cache_interface(opt::Flux.Optimise.AbstractOptimiser) = true

function SciMLBase.__solve(cache::OptimizationCache)
    if cache.data != Optimization.DEFAULT_DATA
        maxiters = length(cache.data)
        data = cache.data
    else
        maxiters = Optimization._check_and_convert_maxiters(cache.solver_args.maxiters)
        data = Optimization.take(cache.data, maxiters)
    end

    # Flux is silly and doesn't have an abstract type on its optimizers, so assume
    # this is a Flux optimizer
    θ = copy(cache.u0)
    G = copy(θ)
    opt = deepcopy(cache.opt)

    local x, min_err, min_θ
    min_err = typemax(eltype(cache.u0)) #dummy variables
    min_opt = 1
    min_θ = cache.u0

    t0 = time()
    Optimization.@withprogress cache.solver_args.progress name="Training" begin for (i, d) in enumerate(data)
        cache.f.grad(G, θ, d...)
        x = cache.f.f(θ, cache.p, d...)
        cb_call = cache.solver_args.callback(θ, x...)
        if !(typeof(cb_call) <: Bool)
            error("The callback should return a boolean `halt` for whether to stop the optimization process. Please see the sciml_train documentation for information.")
        elseif cb_call
            break
        end
        msg = @sprintf("loss: %.3g", x[1])
        cache.solver_args.progress && ProgressLogging.@logprogress msg i/maxiters

        if cache.solver_args.save_best
            if first(x) < first(min_err)  #found a better solution
                min_opt = opt
                min_err = x
                min_θ = copy(θ)
            end
            if i == maxiters  #Last iteration, revert to best.
                opt = min_opt
                x = min_err
                θ = min_θ
                cache.solver_args.callback(θ, x...)
                break
            end
        end
        Flux.update!(opt, θ, G)
    end end

    t1 = time()

    SciMLBase.build_solution(cache, opt, θ, x[1], solve_time = t1 - t0)
    # here should be build_solution to create the output message
end

end
