# ## Лабораторная работа №5. Модель хищник-жертва
# ## Вариант 43

using DifferentialEquations
using Plots

# настройки графики
gr()
default(fmt = :png, size = (1000, 1000), titlefont = font(10))

# функция ищет уже существующую папку plots
# новая папка plots не создается
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

# ## 1. Параметры 
# x(t) - численность хищников
# y(t) - численность жертв
# Вариант 43
# dx/dt = -0.19x + 0.026xy
# dy/dt = 0.18y - 0.032xy

a = 0.19
b = 0.026
c = 0.18
d = 0.032

u0 = [7.308, 5.625]     # начальные условия [хищники, жертвы]
tspan = (0.0, 100.0)

# стационарное состояние системы
# x* = c / d, y* = a / b
x_stationary = a / b  # численность хищников в равновесии
y_stationary = c / d # численность жертв в равновесии

# ## Вывод уравнений
println("Система дифференциальных уравнений:")
println("dx/dt = -", a, "*x(t) + ", b, "*x(t)*y(t)")
println("dy/dt =  ", c, "*y(t) - ", d, "*x(t)*y(t)")
println("x(t) - численность хищников, y(t) - численность жертв")
println()
println("Начальные условия:")
println("x(0) = x0, y(0) = y0")
println("x0 = ", u0[1], " - хищники")
println("y0 = ", u0[2], " - жертвы")
println()
println("Условия стационарного состояния:")
println("-a*x + b*x*y = 0  =>  y* = a / b")
println("c*y - d*x*y = 0   =>  x* = c / d")
println()

println("Стационарное состояние системы:")
println("x* = ", round(x_stationary, digits = 3), " - хищники")
println("y* = ", round(y_stationary, digits = 3), " - жертвы")

# ## 2. Определение системы уравнений
function lotka_volterra!(du, u, p, t)
    x, y = u
    du[1] = -a * x + b * x * y
    du[2] =  c * y - d * x * y
end

# ## 3. Решение системы
prob = ODEProblem(lotka_volterra!, u0, tspan)
sol = solve(prob, Tsit5(), saveat = 0.1)

# ## 4. Визуализация
# графики изменения численности хищников и жертв во времени
p1 = plot(sol,
    title = "Динамика популяций вариант 43",
    xlabel = "Время t",
    ylabel = "Численность",
    label = ["Хищники x(t)" "Жертвы y(t)"],
    lw = 2)

# фазовый портрет: зависимость численности хищников от численности жертв
p2 = plot(sol, vars = (2, 1),
    title = "Фазовый портрет вариант 43",
    xlabel = "Численность жертв y",
    ylabel = "Численность хищников x",
    label = "Траектория",
    lw = 2)

scatter!(p2,
    [y_stationary],
    [x_stationary],
    label = "Стац. точка A($(round(x_stationary, digits = 2)); $(round(y_stationary, digits = 2)))",
    markersize = 5)

layout = plot(p1, p2, layout = (2, 1))
display(layout)

# ## 5. Сохранение результата в уже существующую папку plots
savefig(layout, joinpath(plots_dir, "lab05_predator_prey_stan_43.png"))
println("График сохранен в: ", joinpath(plots_dir, "lab05_predator_prey_stan_43.png"))