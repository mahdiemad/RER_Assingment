using JuMP,CSV,Ipopt,DataFrames

function Case_2(Scenario=1,load=350,money=1)
    #read inputs
    dfGen = CSV.read("..//Data//Genetion Data.csv",DataFrame)

    #parameters 
    Demand=load
    #Emission monetizing factor
    mu=money

    #sets
    setGen=dfGen.Name
    nGen = nrow(dfGen)

    # Create a new model
    model = Model(Ipopt.Optimizer)

    #variables
    @variable(model, dfGen[i,"Pmin"]<=P[i =1:nGen]<=dfGen[i,"Pmax"], start=0)
    
    # Constraints
    @constraint(model, energy_balance, sum(P[i] for i in 1:nGen) == Demand)
   
    if Scenario==1
      #objective: Minimize cost
      @objective(model, Min, sum(dfGen[i,"a"]*P[i]^2+dfGen[i,"b"]*P[i]+dfGen[i,"c"] for i in 1:nGen))
    elseif Scenario==2
      #objective: Minimize cost & Emission
      
      @expression(model, EmissionCost, sum(dfGen[i,5]*P[i] for i in 1:nGen))
      @expression(model, Cost, sum(dfGen[i,"a"]*P[i]^2+dfGen[i,"b"]*P[i]+dfGen[i,"c"] for i in 1:nGen))
      @objective(model, Min, mu*EmissionCost+Cost)
    end
    # Solve the problem
    optimize!(model)

    #print model
    println("==============================================")
    println(model)
    println("==============================================")
    #print solutions
    for i in 1:nGen
      println(dfGen[i,"Name"],"\t=", round(value(P[i]),digits=2),"KW") 
    end
    println("==============================================")
    println("Total Generation=\t",round(value(energy_balance),digits=3),"KW","\nTotal Demand=\t",value(Demand),"KW") 
    println("==============================================")
    println("Obj Function = " , objective_value(model))
    println("==============================================")
end
Case_2()
println("++++++++++++++++++++++++++Case2+++++++++++++++++++\n\n")
Case_2(2)