import Pkg
project_dir = dirname(@__FILE__)
Pkg.activate(project_dir)
Pkg.instantiate()

include("src/GraphTraversing.jl")
import .GraphTraversing

DATA_PATH = joinpath(project_dir, "data", "connection_graph.csv")
GraphTraversing.run(DATA_PATH)
