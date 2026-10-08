using DifferentialEquations
using Plots

gr()
default(fmt = :png, size = (900, 450))

script_name = "lab04_1_43"
experiment_name = "43"


function find_existing_plots_dir()
    current_dir = pwd()

    for _ in 1:6
        candidate = joinpath(current_dir, "plots")

        if isdir(candidate)
            return candidate
        end

        parent_dir = dirname(current_dir)

        if parent_dir == current_dir
            break
        end

        current_dir = parent_dir
    end
end

plots_dir = find_existing_plots_dir()

function save_to_existing_plots(plot_object, file_name)
    output_path = joinpath(plots_dir, file_name)
    savefig(plot_object, output_path)
    println("График сохранен: ", output_path)
end

w = 2.4           # коэффициент при x
g = 0.0             # затухания нет
u0 = [2.0, -1.0]          # начальные условия: x(0)=2, y(0)=-1
tspan = (0.0, 60.0)
step = 0.05

println("Скрипт: ", script_name, ", вариант: ", experiment_name)
println()
println("Задача №1: осциллятор без затухания и без внешней силы")
println("Уравнение: x'' + 2.4x = 0")
println("Система: x' = y, y' = -2.4x")
println()
println("Задача №2: осциллятор с затуханием и без внешней силы")
println("Уравнение: x'' + 7x' + 9x = 0")
println("Система: x' = y, y' = -7y - 9x")
println()
println("Задача №3: осциллятор с затуханием и внешней силой")
println("Уравнение: x'' + 12x' + 3x = 0.2sin(5t)")
println("Система: x' = y, y' = 0.2sin(5t) - 12y - 3x")
println()
println("Начальные условия для всех задач: x(0)=", u0[1], ", y(0)=", u0[2])
println("Интервал: t ∈ [", tspan[1], "; ", tspan[2], "], шаг ", step)
println("Текущая задача: w = ", w, ", g = ", g)

function oscillator_43!(du, u, p, t)
    x, y = u
    du[1] = y
    du[2] = -w * x - g * y
end

prob = ODEProblem(oscillator_43!, u0, tspan)
sol = solve(prob, Tsit5(), saveat=step)

p_solution = plot(sol,
    title="Решение: без затухания_43",
    xlabel="t",
    ylabel="x(t), y(t)",
    label=["x(t)" "y(t)"],
    lw=2
)

p_phase = plot(sol,
    vars=(1, 2),
    title="Фазовый портрет_43",
    xlabel="x",
    ylabel="y = x'",
    label="траектория",
    lw=2
)

result_plot = plot(p_solution, p_phase, layout=(1, 2), size=(1000, 450))
display(result_plot)

save_to_existing_plots(result_plot, "lab04_1_43.png")
