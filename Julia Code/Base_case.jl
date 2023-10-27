using JuMP,GLPK

function base_model()

    # Create a new model
    model = Model(GLPK.Optimizer)
    # Decision Variables
    @variable(model, 0 <= wind_energy <= 40) # Wind energy integrated
    @variable(model, 0 <= solar_energy <= 50) # Solar energy integrated
    @variable(model, 0 <= stored_energy <= 10) # Energy to store for later use
    # Objective: Minimize cost
    @objective(model, Min, 20*wind_energy + 25*solar_energy + 10*stored_energy)
    # Constraints
    @constraint(model, energy_balance, wind_energy + solar_energy + stored_energy == 100)
    # Solve the problem
    optimize!(model)

    #print model
    println("==============================================")
    println(model)
    println("==============================================")
    #print solutions
    println("wind_energy = $(value(wind_energy))")
    println("solar_energy = $(value(solar_energy))")
    println("stored_energy = $(value(stored_energy))")
    println("Obj Function = $(objective_value(model))")
    println("==============================================")
end

base_model()