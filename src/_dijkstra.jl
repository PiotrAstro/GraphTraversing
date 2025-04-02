
function dijkstra(general_graph::Dict{Symbol, Node}, from::Symbol, to::Symbol, leave_time::Int, mode::Symbol)::ResultPath
    if mode == :time
        graph = construct_time_graph(general_graph)
    elseif mode == :changes
        graph = construct_changes_graph(general_graph)
    else
        throw(ArgumentError("Invalid mode: $mode"))
    end

    return dijkstra!(graph, from, to, leave_time)
end

function dijkstra!(graph::Dict{Symbol, N}, from::Symbol, to::Symbol, leave_time::Int, get_cost::Function=get_cost)::ResultPath where {N<:NodeOptimization}
    from_node = graph[from]
    to_node = graph[to]

    set_cost!(from_node, 0)
    set_first_arrival_time!(from_node, leave_time)
    queue = DataStructures.PriorityQueue{N, Float64}()
    for node in values(graph)
        DataStructures.enqueue!(queue, node, get_cost(node))
    end

    while !isempty(queue)
        node = DataStructures.dequeue!(queue)
        if node == to_node
            return ResultPath(
                path=get_path(node, graph),
                cost=get_cost(node) - get_cost(from_node),
                arrival_time=get_arrival_time(node),
                ride_time=get_arrival_time(node) - get_arrival_time(from_node)
            )
        end

        for node_to in get_neighbours(node)
            if node_to in keys(queue)
                if update!(node, node_to)
                    DataStructures.dequeue!(queue, node_to)
                    DataStructures.enqueue!(queue, node_to, get_cost(node_to))
                end
            end
            # if update!(node, node_to)
            #     if node_to in keys(queue)
            #         DataStructures.dequeue!(queue, node_to)
            #     end
            #     DataStructures.enqueue!(queue, node_to, get_cost(node_to))
            # end
        end
    end

    throw(ArgumentError("No path found from $from to $to"))
end