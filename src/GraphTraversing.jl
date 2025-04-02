module GraphTraversing

import CSV
import DataFrames
import DataStructures
import Printf

include("_graphs.jl")
include("_construction.jl")
include("_dijkstra.jl")
include("_a_star.jl")
include("_tabu_search.jl")
include("_printing.jl")

export run

function run(data_path::String)
    println("Loading data from $data_path")
    general_graph = construct_graph(data_path)
    println("Data loaded")
    deliminator = repeat("-", 50)
    while true
        println("\n\n$deliminator\n\n")
        user_operation = get_user_operation()
        if user_operation == :exit
            println("Exiting...")
            break
        elseif user_operation == :single
            user_algorithm = get_user_algorithm()
            if user_algorithm == dijkstra
                println("Using Dijkstra's algorithm")
                mode = :time
                println("Using time mode")
            elseif user_algorithm == a_star
                println("Using A* algorithm")
                mode = get_user_mode()
                println("Using $mode mode")
            end
            time_leave = get_user_time()
            stops = get_user_stops(general_graph, 2)
            time_start = time()
            result = user_algorithm(general_graph, stops[1], stops[2], time_leave, mode)
            time_end = time()

            println("\n\nResult:")
            Printf.@printf("Time taken: %.2f seconds\n", time_end - time_start)
            print_path(result)
        elseif user_operation == :many
            println("Using A* algorithm")
            mode = get_user_mode()
            println("Using $mode mode")
            time_leave = get_user_time()
            stops = get_user_stops(general_graph, 3)
            time_start = time()
            result = tabu_search(general_graph, stops, time_leave, mode)
            time_end = time()

            println("\n\nResult:")
            Printf.@printf("Time taken: %.2f seconds\n", time_end - time_start)
            print_tabu_result(result)
        end

        println("\n\nPress Enter to continue...")
        input = readline()
    end
end

# general_graph = construct_graph(raw"C:\Users\piotrz\Downloads\connection_graph.csv")
# time_graph = construct_time_graph(general_graph)
# changes_graph = construct_changes_graph(general_graph)

# println("Starting tests")

# from = Symbol("Smocza")
# to = Symbol("Rodła")
# time_leave = str_to_minutes("12:00")

# # from = Symbol("Wilczyce - Borowa")
# # to = Symbol("Rynek")
# # time_leave = str_to_minutes("23:20")

# result = dijkstra(general_graph, from, to, time_leave, :time)
# println("time_ride: ", result.cost)
# print_path(result)

# result = dijkstra(general_graph, from, to, time_leave, :changes)
# println("changes_ride: ", result.cost)
# print_path(result)

# result = a_star(general_graph, from, to, time_leave, :time)
# println("a_star_ride: ", result.cost)
# print_path(result)

# result = a_star(general_graph, from, to, time_leave, :changes)
# println("a_star_changes_ride: ", result.cost)
# print_path(result)


# @time dijkstra(general_graph, from, to, time_leave, :time)
# @time dijkstra(general_graph, from, to, time_leave, :changes)
# @time a_star(general_graph, from, to, time_leave, :time)
# @time a_star(general_graph, from, to, time_leave, :changes)
# print("\n\n\n")


# println("Starting Tabu Search")
# time_leave = str_to_minutes("12:00")
# stops = [
#     Symbol("Mokra"),
#     Symbol("Rodła"),
#     Symbol("Zbożowa"),
#     # Symbol("DWORZEC GŁÓWNY"),
#     # Symbol("LEŚNICA"),
#     Symbol("Lekarska"),
#     Symbol("Smocza"),
# ]

# result = tabu_search(general_graph, stops, time_leave, :time)
# print_tabu_result(result)

# result = tabu_search(general_graph, stops, time_leave, :changes)
# print_tabu_result(result)

# @time tabu_search(general_graph, stops, time_leave, :time)
# @time tabu_search(general_graph, stops, time_leave, :changes)
end # module