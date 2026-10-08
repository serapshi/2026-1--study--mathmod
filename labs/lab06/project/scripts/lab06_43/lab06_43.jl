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

N = 5505
I0 = 45
R0 = 3
a = 0.01
b = 0.02
S0 = N - I0 - R0
tspan = (0.0, 100.0)
u0 = [S0, I0, R0]

println("Система дифференциальных уравнений:")
println("dS/dt = 0")
println("dI/dt = -b* I")
println("dR/dt = b * I")
println()

function epidemic1!(du, u, p, t) # I(t) <= I*
    S, I, R = u
    du[1] = 0
    du[2] =  - b * I
    du[3] = b * I
end

function epidemic2!(du, u, p, t) # I(t) > I*
    S, I, R = u
    du[1] = -a * S
    du[2] = a * S  - b * I
    du[3] = b * I
end

prob1 = ODEProblem(epidemic1!, u0, tspan)
sol1 = solve(prob1, Tsit5(), saveat = 0.1)

prob2 = ODEProblem(epidemic2!, u0, tspan)
sol2 = solve(prob2, Tsit5(), saveat = 0.1)

p1 = plot(sol1,
    title = "Эпидемия при I(t) <= I* вариант 43",
    xlabel = "Время t",
    ylabel = "Численность",
    label = ["S(t) - восприимчивых " "I(t) - инфицированные" "R(t) - с иммунитетом"],
    lw = 2)

p2 = plot(sol2,
    title = "Эпидемия при I(t) > I* вариант 43",
    xlabel = "Время t",
    ylabel = "Численность",
    label = ["S(t) - восприимчивых " "I(t) - инфицированные" "R(t) - с иммунитетом"],
    lw = 2)

layout = plot(p1, p2, layout = (2, 1))
display(layout)

savefig(layout, joinpath(plots_dir, "lab05_epidemy_43.png"))
println("График сохранен в: ", joinpath(plots_dir, "lab05_epidemy_43.png"))
