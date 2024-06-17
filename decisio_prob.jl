using CSV, DataFrames, JuMP, Gurobi, Random, LinearAlgebra

# Create sets P and D for production and distribution centers
production = ["Baltimore", "Cleveland", "Little Rock", "Birmingham", "Charleston"]
distribution = ["Columbia", "Indianapolis", "Lexington", "Nashville", "Richmond", "St. Louis"]

path = "https://raw.githubusercontent.com/Gurobi/modeling-examples/master/optimization101/Modeling_Session_1/"

# Read in the data
transp_cost = CSV.read(download(path * "cost.csv"), DataFrame)

# Convert the DataFrame to a Series-like structure by selecting the 'cost' column
transp_cost_series = transp_cost[:, "cost"]

# Pivot the DataFrame to view the costs more easily
pivot_df = unstack(transp_cost, :production, :distribution, :cost)

# Define the production and distribution arrays
production_alias = ["prod1", "prod2", "prod3", "prod4", "prod5"]
distribution_alias = ["dist1", "dist2", "dist3", "dist4", "dist5", "dist6"]

# Create the max_prod series as a DataFrame
max_prod_df = DataFrame(production=production_alias, max_production=[180, 200, 140, 80, 180])

# Create the n_demand series as a DataFrame
n_demand_df = DataFrame(distribution=distribution_alias, demand=[89, 95, 121, 101, 116, 181])

# Display the data frames
println(max_prod_df)
println(n_demand_df)

# Set a fraction for some calculation (not used further in this example)
frac = 0.75

# Seed the random number generator for reproducibility
Random.seed!(1234)

# Create the model
m = Model(Gurobi.Optimizer)

# Create a dictionary to store the decision variables
x = Dict{Tuple{String, String}, VariableRef}()
# Loop through each production and distribution combination to create a decision variable
for p in production, d in distribution
    x[(p, d)] = @variable(m, base_name="$(p)_to_$(d)", lower_bound=0, integer=true)
end

# Display the decision variables
println("Decision Variables:")
for (key, value) in x
    println("$key: $value")
end

# Add the objective function
@objective(m, Min, sum(transp_cost[(transp_cost.production .== p) .& (transp_cost.distribution .== d), :cost][1] * x[(p, d)] for p in production, d in distribution))

# Add constraints (example constraints)
for i in 1:length(production)
    @constraint(m, sum(x[(production[i], d)] for d in distribution) <= max_prod_df[i, :max_production])
end

for j in 1:length(distribution)
    @constraint(m, sum(x[(p, distribution[j])] for p in production) >= n_demand_df[j, :demand])
end

# Solve the model
optimize!(m)

# Print the solution
println("Objective value: ", objective_value(m))
for (key, value) in x
    println("$key: ", value, " = ", value)
end