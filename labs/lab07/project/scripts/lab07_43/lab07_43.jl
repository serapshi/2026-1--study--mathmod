using DifferentialEquations
using Plots

gr()
default(fmt = :png, size = (1000, 1000), titlefont = font(10))

function find_plots_dir()
    candidates = [
        joinpath(pwd(), "plots"),
        joinpath(dirname(pwd()), "plots"),
        joinpath(dirname(dirname(pwd())), "plots")
    ]

    for path in candidates
        if isdir(path)
            return path
        end
    end
end

plots_dir = find_plots_dir()

n0 = 22.0
N = 3310.0
tspan = (0.0, 30.0)
tspan2 = (0.0, 0.6)
u0 = [n0]

println("Модель распространения рекламы:")
println("dn/dt = (alpha1(t) + alpha2(t) * n(t)) * (N - n(t))")
println()

function ads_perf1!(du, u, p, t) #
    n = u[1]
    du[1] = (0.211 + 0.000011 * n) * (N - n)
end


function ads_perf2!(du, u, p, t) #
    n = u[1]
    du[1] = (0.0000311 + 0.21 * n) * (N - n)
end

function ads_perf3!(du, u, p, t) #
    n = u[1]
    du[1] = (0.511 * sin(t) + 0.311 * sin(t) * n) * (N - n)
end

prob1 = ODEProblem(ads_perf1!, u0, tspan)
sol1 = solve(prob1, Tsit5(), saveat = 0.1)

prob2 = ODEProblem(ads_perf2!, u0, tspan2)
sol2 = solve(prob2, Tsit5(), saveat = 0.01)

prob3 = ODEProblem(ads_perf3!, u0, tspan)
sol3 = solve(prob3, Tsit5(), saveat = 0.1)

function growth_rate2(t)
    n = sol2(t)[1]
    return (0.0000311 + 0.21 * n) * (N - n)
end


sample_t2 = collect(range(tspan2[1], tspan2[2], length = 30000))
speeds = [growth_rate2(t) for t in sample_t2]
max_index = argmax(speeds)
t_max = sample_t2[max_index]
n_max = sol2(t_max)[1]
max_speed2 = speeds[max_index]

println(t_max)

p1 = plot(sol1,
    title = "Построить график распространения рекламы о салоне красоты",
    xlabel = "Время t",
    ylabel = "Численность",
    label = ["N - потенциальных клиенты " "N(0) - осведомленные клиенты "],
    lw = 2)

p2 = plot(sol2,
    title = "Построить график распространения рекламы о салоне красоты",
    xlabel = "Время t",
    ylabel = "Численность",
    label = ["N - потенциальных клиенты " "N(0) - осведомленные клиенты "],
    lw = 2)

p3 = plot(sol3,
    title = "Построить график распространения рекламы о салоне красоты",
    xlabel = "Время t",
    ylabel = "Численность",
    label = ["N - потенциальных клиенты " "N(0) - осведомленные клиенты "],
    lw = 2)



layout1 = plot(p1, p2, p3, layout = (3, 1))
display(layout1)

savefig(layout1, joinpath(plots_dir, "lab07_43.png"))
println("График сохранен в: ", joinpath(plots_dir, "lab07_ads_43.png"))
