module GraphTraversing

import CSV
import DataFrames
import DataStructures
import Printf

include("_graphs.jl")
include("_printing.jl")
include("_construction.jl")
include("_dijkstra.jl")
include("_a_star.jl")

general_graph = construct_graph(raw"C:\Users\piotrz\Downloads\connection_graph.csv")
time_graph = construct_time_graph(general_graph)
changes_graph = construct_changes_graph(general_graph)

println("Starting tests")

# from = Symbol("Klęka")
# to = Symbol("Kątna")
# time_leave = str_to_minutes("12:00")

from = Symbol("BARTOSZOWICE")
to = Symbol("LEŚNICA")
time_leave = str_to_minutes("12:00")

time_ride, cost = dijkstra(general_graph, from, to, time_leave, :time)
println("time_ride: ", cost)
print_path(time_ride)

changes_ride, cost = dijkstra(general_graph, from, to, time_leave, :changes)
println("changes_ride: ", cost)
print_path(changes_ride)

a_star_ride, cost = a_star(general_graph, from, to, time_leave, :time)
println("a_star_ride: ", cost)
print_path(a_star_ride)

a_star_changes_ride, cost = a_star(general_graph, from, to, time_leave, :changes)
println("a_star_changes_ride: ", cost)
print_path(a_star_changes_ride)

@time dijkstra(general_graph, from, to, time_leave, :time)
@time dijkstra(general_graph, from, to, time_leave, :changes)
@time a_star(general_graph, from, to, time_leave, :time)
@time a_star(general_graph, from, to, time_leave, :changes)
print("\n\n\n")

end # module