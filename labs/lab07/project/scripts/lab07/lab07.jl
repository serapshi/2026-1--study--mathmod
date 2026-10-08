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

n0 = 11.0
N = 2000.0
tspan = (0.0, 30.0)
u0 = [n0]

println("Модель распространения рекламы:")
println("dn/dt = (alpha1(t) + alpha2(t) * n(t)) * (N - n(t))")
println()

function ads_perf!(du, u, p, t) #
    alpha1, alpha2, N = p
    n = u[1]
    du[1] = (alpha1(t) +alpha2(t) * n) * (N - n)
end

a1(t) = 0.0
a2(t) = 0.055
prob1 = ODEProblem(ads_perf!, u0, tspan, [a1, a2, N])
sol1 = solve(prob1, Tsit5(), saveat = 0.1)
prob2 = ODEProblem(ads_perf!, u0, tspan, [a2, a1, N])
sol2 = solve(prob2, Tsit5(), saveat = 0.1)



a1_2(t) = 0.002
a2_2(t) = 0.0000055
prob3 = ODEProblem(ads_perf!, u0, tspan, [a1_2, a2_2, N])
sol3 = solve(prob3, Tsit5(), saveat = 0.1)
prob4 = ODEProblem(ads_perf!, u0, tspan, [a2_2, a1_2, N])
sol4 = solve(prob4, Tsit5(), saveat = 0.1)

function growth_rate(sol, alpha1, alpha2, t)
    n = sol(t)[1]
    return (alpha1(t) + alpha2(t) * n) * (N - n)
end

function find_max_speed(sol, alpha1, alpha2)
    sample_t = collect(range(tspan[1], tspan[2], length = 30000))
    speeds = [growth_rate(sol, alpha1, alpha2, t) for t in sample_t]
    idx = argmax(speeds)
    return sample_t[idx], sol(sample_t[idx])[1], speeds[idx]
end

t_max1, n_max1, v_max1 = find_max_speed(sol1, a1, a2)

println(t_max1)

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

p4 = plot(sol4,
    title = "Построить график распространения рекламы о салоне красоты",
    xlabel = "Время t",
    ylabel = "Численность",
    label = ["N - потенциальных клиенты " "N(0) - осведомленные клиенты "],
    lw = 2)

layout1 = plot(p1, p2, layout = (2, 1))
display(layout1)

layout2 = plot(p3, p4, layout = (2, 1))
display(layout2)

savefig(layout1, joinpath(plots_dir, "lab07_ads_zeros.png"))
println("График сохранен в: ", joinpath(plots_dir, "lab07_ads.png"))

savefig(layout2, joinpath(plots_dir, "lab07_ads_diff.png"))
