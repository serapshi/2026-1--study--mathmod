using DrWatson
@quickactivate "project"
using DifferentialEquations
using DataFrames
using Plots
using JLD2
using BenchmarkTools

script_name = "lab02_43"
mkpath(plotsdir(script_name))
mkpath(datadir(script_name))

function pursuit!(dr, r, p, θ)
    n = p.n
    dr[1] = r[1] / sqrt(n^2 - 1)
end

k = base_params[:k]
n = base_params[:n]
x1 = k / (n + 1)
x2 = k / (n - 1)

println("Уравнение движения катера:")
println("  dr/dθ = r / sqrt(n^2 − 1)")
println()
println("Случай 1 (катер и лодка по одну сторону от полюса):")
println("  θ0 = 0,   r0 = x1 = k / (n + 1) = ", round(x1; digits=3), " км")
println("  r(θ) = x1 · exp(θ / sqrt(n^2 − 1))")
println()
println("Случай 2 (полюс между катером и лодкой):")
println("  θ0 = −π,  r0 = x2 = k / (n − 1) = ", round(x2; digits=3), " км")
println("  r(θ) = x2 · exp((θ + π) / sqrt(n^2 − 1))")
println()
println("При n = ", n, ":  sqrt(n^2 − 1) = ", round(sqrt(n^2 - 1); digits=4))

base_params = Dict(
    :n => 4.0,
    :k => 16.2,
    :phi1 => π/2,
    :phi2 => 3π/4,
    :tspan1 => (0.0, π/2 + 2π),
    :tspan2 => (-π, 3π/4 + 2π),
    :saveat => 0.01,
    :solver => Tsit5(),
    :experiment_name => "43_1"
)

function run_single_experiment(params::Dict)
    @unpack k, n, phi1, phi2, tspan1, tspan2, solver, saveat = params

    x1 = k / (n + 1)
    x2 = k / (n - 1)
    denom = sqrt(n^2 - 1)

    sol1 = solve(ODEProblem(pursuit!, [x1], tspan1, (n=n,)), solver; saveat=saveat)
    θ1 = sol1.t
    r1 = first.(sol1.u)
    r1_int = x1 * exp(phi1 / denom)
    intersection1 = (r1_int * cos(phi1), r1_int * sin(phi1))

    sol2 = solve(ODEProblem(pursuit!, [x2], tspan2, (n=n,)), solver; saveat=saveat)
    θ2 = sol2.t
    r2 = first.(sol2.u)
    r2_int = x2 * exp((phi2 + π) / denom)
    intersection2 = (r2_int * cos(phi2), r2_int * sin(phi2))

    return Dict(
        "x1" => x1,
        "x2" => x2,
        "case1_theta" => θ1,
        "case1_r" => r1,
        "case1_x" => r1 .* cos.(θ1),
        "case1_y" => r1 .* sin.(θ1),
        "case1_intersection" => intersection1,
        "case2_theta" => θ2,
        "case2_r" => r2,
        "case2_x" => r2 .* cos.(θ2),
        "case2_y" => r2 .* sin.(θ2),
        "case2_intersection" => intersection2,
        "parameters" => params
    )
end

data, path = produce_or_load(
    datadir(script_name, "single"),
    base_params,
    run_single_experiment,
    prefix = "pursuit",
    tag = false,
    verbose = true
)

println("x1 = ", round(data["x1"]; digits=3), " км")
println("x2 = ", round(data["x2"]; digits=3), " км")
println("Пересечение 1: ", data["case1_intersection"])
println("Пересечение 2: ", data["case2_intersection"])

p1 = plot(data["case1_x"], data["case1_y"],
    label="Катер", xlabel="x, км", ylabel="y, км",
    title="Случай 1", lw=2, aspect_ratio=:equal, grid=true)
t1 = range(0, 1.2 * hypot(data["case1_intersection"]...), length=100)
plot!(p1, t1 .* cos(base_params[:phi1]), t1 .* sin(base_params[:phi1]),
    label="Лодка", ls=:dash, lw=2, color=:orange)
scatter!(p1, [data["case1_intersection"][1]], [data["case1_intersection"][2]],
    label="Пересечение", color=:red, markersize=6)

p2 = plot(data["case2_x"], data["case2_y"],
    label="Катер", xlabel="x, км", ylabel="y, км",
    title="Случай 2", lw=2, aspect_ratio=:equal, grid=true)
t2 = range(0, 1.2 * hypot(data["case2_intersection"]...), length=100)
plot!(p2, t2 .* cos(base_params[:phi2]), t2 .* sin(base_params[:phi2]),
    label="Лодка", ls=:dash, lw=2, color=:orange)
scatter!(p2, [data["case2_intersection"][1]], [data["case2_intersection"][2]],
    label="Пересечение", color=:red, markersize=6)

base_plot = plot(p1, p2, layout=(1, 2), size=(1000, 500))
savefig(plotsdir(script_name, "base_experiment.png"))

param_grid = Dict(
    :k => [16.2],
    :n => [2.0, 3.0, 4.0, 5.0, 6.0],
    :phi1 => [π/2],
    :phi2 => [3π/4],
    :tspan1 => [(0.0, π/2 + 2π)],
    :tspan2 => [(-π, 3π/4 + 2π)],
    :solver => [Tsit5()],
    :saveat => [0.01],
    :experiment_name => ["parametric_scan"]
)

all_params = dict_list(param_grid)

all_results = []

for (i, params) in enumerate(all_params)
    println("Прогресс: $i/$(length(all_params)) | n = $(params[:n])")

    data_i, path_i = produce_or_load(
        datadir(script_name, "parametric_scan"),
        params,
        run_single_experiment,
        prefix = "scan",
        tag = false,
        verbose = false
    )

    push!(all_results, merge(params, Dict(
        :x1 => data_i["x1"],
        :x2 => data_i["x2"],
        :intersection1_x => data_i["case1_intersection"][1],
        :intersection1_y => data_i["case1_intersection"][2],
        :intersection2_x => data_i["case2_intersection"][1],
        :intersection2_y => data_i["case2_intersection"][2],
        :filepath => path_i
    )))
end

results_df = DataFrame(all_results)
println(results_df[!, [:n, :x1, :x2, :intersection1_x, :intersection2_x]])

p3 = plot(size=(800, 500), dpi=150)
p4 = plot(size=(800, 500), dpi=150)

for params in all_params
    data_i, _ = produce_or_load(
        datadir(script_name, "parametric_scan"),
        params,
        run_single_experiment,
        prefix = "scan"
    )
    plot!(p3, data_i["case1_x"], data_i["case1_y"], label="n = $(params[:n])", lw=2, alpha=0.85)
    plot!(p4, data_i["case2_x"], data_i["case2_y"], label="n = $(params[:n])", lw=2, alpha=0.85)
end

plot!(p3, xlabel="x, км", ylabel="y, км", title="Случай 1",
    legend=:topleft, aspect_ratio=:equal, grid=true)
plot!(p4, xlabel="x, км", ylabel="y, км", title="Случай 2",
    legend=:topleft, aspect_ratio=:equal, grid=true)

savefig(p3, plotsdir(script_name, "scan_case1.png"))
savefig(p4, plotsdir(script_name, "scan_case2.png"))

p5 = plot(results_df.n, results_df.intersection1_x,
    seriestype=:scatter, label="случай 1",
    xlabel="n", ylabel="координата, км",
    title="Координаты точки пересечения",
    markersize=8, markercolor=:blue, legend=:topright)
plot!(p5, results_df.n, results_df.intersection2_x,
    seriestype=:scatter, label="случай 2",
    markersize=8, markercolor=:red)
plot!(p5, results_df.n, results_df.x1, label="x1 = k/(n+1)", lw=2, ls=:dash, color=:blue)
plot!(p5, results_df.n, results_df.x2, label="x2 = k/(n-1)", lw=2, ls=:dash, color=:red)

savefig(p5, plotsdir(script_name, "intersection_vs_n.png"))

benchmark_results = []

for n_value in param_grid[:n]
    bench_params = Dict(
        :k => 16.2,
        :n => n_value,
        :phi1 => π/2,
        :phi2 => 3π/4,
        :tspan1 => (0.0, π/2 + 2π),
        :tspan2 => (-π, 3π/4 + 2π),
        :solver => Tsit5(),
        :saveat => 0.01
    )

    function benchmark_run()
        return run_single_experiment(bench_params)
    end

    b = @benchmark $benchmark_run() samples=50 evals=1
    push!(benchmark_results, (n=n_value, time=median(b).time/1e9))
    println("n = $n_value: ", round(median(b).time/1e9; digits=4), " сек")
end

bench_df = DataFrame(benchmark_results)
p6 = plot(bench_df.n, bench_df.time,
    seriestype=:scatter,
    label="Время", xlabel="n", ylabel="Время, сек",
    title="Время вычисления от n",
    markersize=8, markercolor=:green, legend=:topleft)

savefig(p6, plotsdir(script_name, "computation_time_vs_n.png"))

@save datadir(script_name, "all_results.jld2") base_params param_grid all_params results_df bench_df
@save datadir(script_name, "all_plots.jld2") p1 p2 p3 p4 p5 p6
