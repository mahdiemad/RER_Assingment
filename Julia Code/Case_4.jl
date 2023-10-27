using JuMP,CSV,Ipopt,DataFrames

function Case_4(load=330,money=0.1)
    #read inputs
    dfGen = CSV.read("..//Data//Genetion Data_noESS.csv",DataFrame)
    dfTime= CSV.read("..//Data//Daily_Profile.csv",DataFrame)

    #parameters 
    Demand=load
    #Emission monetizing factor
    mu=money
    ##Storage efficiency factor
    gamma=0.95
    #sets 
    nGen = nrow(dfGen)
    nTime= nrow(dfTime)

    # Create a new model
    model = Model(Ipopt.Optimizer)

    #variables
    function P_upper_bound(i,t)
      if dfGen[i,"Name"]=="Wind"
          return dfGen[i,"Pmax"]*dfTime[t,"Wind"]
      elseif (dfGen[i,"Name"]=="Solar")
          return dfGen[i,"Pmax"]*dfTime[t,"Solar"]
      else 
          return dfGen[i,"Pmax"]
      end
    end

    @variable(model, dfGen[i,"Pmin"]<=P[i =1:nGen,t=1:nTime]<=P_upper_bound(i,t), start=0)

    # Storage Dcharge/Charge & SOC Variable
    @variable(model, 10<=SOC[t=1:nTime]<=120, start=10)
    @variable(model, 10<=Pch[t=1:nTime]<=40, start=0)
    @variable(model, 10<=Pdch[t=1:nTime]<=40, start=0)
        
    # Constraints
    @constraint(model,energy_balance[t=1:nTime], sum(P[i,t] for i in 1:nGen) == Demand*dfTime[t,"Demand"])
    @constraint(model, Ramp_up[t=1:nTime-1,i=4:nGen], P[i,t+1]-P[i,t]<=0.2*dfGen[i,"Pmax"])
    @constraint(model, Ramp_down[t=1:nTime-1,i=4:nGen], P[i,t+1]-P[i,t]<=0.2*dfGen[i,"Pmax"])

    @constraint(model, SOC_constraint[t=2:nTime], SOC[t]==SOC[t-1]+gamma*Pch[t]-Pdch[t]/gamma)


    #objective: Minimize cost & Emission  
    @expression(model, EmissionCost, sum(dfGen[i,5]*P[i,t] for i in 1:nGen for t in 1:nTime))
    @expression(model, Cost, 20*sum( Pdch[t]-Pch[t] for t in 1:nTime)+sum(dfGen[i,"a"]*P[i,t]^2+dfGen[i,"b"]*P[i,t]+dfGen[i,"c"] for i in 1:nGen for t in 1:nTime))
    @objective(model, Min, mu*EmissionCost+Cost)
  
    # Solve the problem
    optimize!(model)

    #print model
    println("==============================================")
    # println(model)
    println("==============================================")
    #print solutions
    for t in 1:nTime
      println("Hour:\t",t,"\t==============================================")
      for i in 1:nGen
        println(dfGen[i,"Name"],"\t=", round(value(P[i,t]),digits=2),"KW") 
      end
      println("Total Generation=\t",round(value(energy_balance[t]),digits=3),"KW","\nTotal Demand=\t",value(Demand)*dfTime[t,"Demand"],"KW") 
    end
    println("====================end=======================")
    println("Obj Function = ", objective_value(model))
    println("==============================================")
end
Case_4(300,0.1)