
function heuristic_kilometers(node1::NodeOptimization, node2::NodeOptimization)::Float64
    return get_distance_kilometers(node1, node2) / 15.0 * 60.0  # 15 km/h
end

function heuristic_changes(node1::NodeOptimization, node2::NodeOptimization)::Float64
    return heuristic_kilometers(node1, node2) / 60.0 + get_arrival_time(node1) / 120.0 # approximated 1 hour per change
end

function a_star(general_graph::Dict{Symbol, Node}, from::Symbol, to::Symbol, leave_time::Int, mode::Symbol)::ResultPath
    if mode == :time
        graph = construct_time_graph(general_graph)
        heuristic_function = heuristic_kilometers
    elseif mode == :changes
        graph = construct_changes_graph(general_graph)
        heuristic_function = heuristic_changes
    else
        throw(ArgumentError("Invalid mode: $mode"))
    end

    return a_star!(graph, from, to, leave_time, heuristic_function)
end

function a_star!(graph::Dict{Symbol, N}, from::Symbol, to::Symbol, leave_time::Int, heuristic_function::Function=heuristic_kilometers, get_cost::Function=get_cost)::ResultPath where {N<:NodeOptimization}
    from_node = graph[from]
    to_node = graph[to]

    set_cost!(from_node, 0)
    set_first_arrival_time!(from_node, leave_time)

    closed_set = Set{N}()
    open_queue = DataStructures.PriorityQueue{N, Float64}()
    DataStructures.enqueue!(open_queue, from_node, 0.0)
    while !DataStructures.isempty(open_queue)
        current_node = DataStructures.dequeue!(open_queue)
        push!(closed_set, current_node)

        if current_node == to_node
            return ResultPath(
                path=get_path(current_node, graph),
                cost=get_cost(current_node) - get_cost(from_node),
                arrival_time=get_arrival_time(current_node),
                ride_time=get_arrival_time(current_node) - get_arrival_time(from_node)
            )
        end

        for neighbour in get_neighbours(current_node)
            if !(neighbour in closed_set) && !haskey(open_queue, neighbour)
                update!(current_node, neighbour)

                f_value = get_cost(neighbour) + heuristic_function(neighbour, to_node)
                DataStructures.enqueue!(open_queue, neighbour, f_value)
            else
                if update!(current_node, neighbour)
                    if neighbour in closed_set
                        delete!(closed_set, neighbour)
                    end
                    if neighbour in keys(open_queue)
                        DataStructures.dequeue!(open_queue, neighbour)
                    end

                    f_value = get_cost(neighbour) + heuristic_function(neighbour, to_node)
                    DataStructures.enqueue!(open_queue, neighbour, f_value)
                end
            end
        end
    end

    throw(ArgumentError("No path found"))
end
