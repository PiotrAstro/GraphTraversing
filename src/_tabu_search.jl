@kwdef struct TabuResult
    stops::Vector{Symbol}
    result_vector::Vector{ResultPath}
    cost::Float64
end

function TabuResult(cache::Dict{Vector{Symbol}, Vector{ResultPath}}, stops::Vector{Symbol}, general_graph::Dict{Symbol, Node}, leave_time::Int, mode::Symbol)::TabuResult
    result_path = calculate_result!(cache, stops, general_graph, leave_time, mode)
    return TabuResult(
        stops=stops,
        result_vector=result_path,
        cost=get_cost(result_path)
    )
end

function calculate_result!(cache::Dict{Vector{Symbol}, Vector{ResultPath}}, stops::Vector{Symbol}, general_graph::Dict{Symbol, Node}, leave_time::Int, mode::Symbol)::Vector{ResultPath}
    result_vector = ResultPath[]
    cached_length = 0
    i = length(stops)
    while i > 1
        stops_tmp = stops[1:i]
        if haskey(cache, stops_tmp)
            cached_length = i
            result_vector = copy(cache[stops_tmp])
            leave_time = result_vector[end].arrival_time
            break
        end
        i -= 1
    end

    for i in max(2, cached_length + 1):length(stops)
        new_result = a_star(general_graph, stops[i-1], stops[i], leave_time, mode)
        push!(result_vector, new_result)
        leave_time = new_result.arrival_time
        cache[stops[1:i]] = copy(result_vector)
    end
    return result_vector
end

function get_cost(result_vector::Vector{ResultPath})::Float64
    return sum(ride -> ride.cost, result_vector)
end

@kwdef struct Tabu
    tabu_list::Vector{Vector{Symbol}}
    max_size::Int
end

function Tabu(max_size::Int)::Tabu
    return Tabu(
        tabu_list=Vector{Vector{Symbol}}(),
        max_size=max_size
    )
end

function is_tabu(tabu::Tabu, result_vector::Vector{Symbol})::Bool
    return result_vector in tabu.tabu_list
end

function add_tabu!(tabu::Tabu, result_vector::Vector{Symbol})
    if length(tabu.tabu_list) >= tabu.max_size
        popfirst!(tabu.tabu_list)
    end
    push!(tabu.tabu_list, result_vector)
end

function add_tabu!(tabu::Tabu, result_vectors::Vector{Vector{Symbol}})
    for result_vector in result_vectors
        add_tabu!(tabu, result_vector)
    end
end

# --------------------------------------------------------------
# The search itself

function tabu_search(general_graph::Dict{Symbol, Node}, stops::Vector{Symbol}, leave_time::Int, mode::Symbol; max_iter::Int=10, ops_num::Int=5)::TabuResult
    cache = Dict{Vector{Symbol}, Vector{ResultPath}}()

    if stops[1] != stops[end]
        push!(stops, stops[1])
    end
    if length(Set(stops[1:end-1])) != length(stops[1:end-1])
        throw(ArgumentError("Stops must be unique"))
    end

    tabu = Tabu(20)
    s_current = TabuResult(cache, stops, general_graph, leave_time, mode)
    s_best = s_current

    for iteration in 1:max_iter
        # println("Iteration: ", iteration)
        # println("Current cost: ", s_current.cost)
        # println("Best cost: ", s_best.cost)
        for operation in 1:ops_num
            neighbours = generate_neighbours(s_current.stops)
            neighbours_calulated = [TabuResult(cache, x, general_graph, leave_time, mode) for x in neighbours]
            neighbours_filtered = filter(x -> !is_tabu(tabu, x.stops) || aspire(x, s_best), neighbours_calulated)

            if isempty(neighbours_filtered)
                break
            end

            s_current = neighbours_filtered[argmin([x.cost for x in neighbours_filtered])]

            # really this one?
            # add_tabu!(tabu, neighbours)

            # maybe that one?
            add_tabu!(tabu, s_current.stops)
        end
        if s_best.cost > s_current.cost
            s_best = s_current
        end
    end

    return s_best
end

function generate_neighbours(initial_vector::Vector{Symbol})::Vector{Vector{Symbol}}
    result_vectors = Vector{Vector{Symbol}}()
    for i in 2:length(initial_vector)-1
        for j in i+1:length(initial_vector)-1
            new_vector = copy(initial_vector)
            new_vector[i], new_vector[j] = new_vector[j], new_vector[i]
            push!(result_vectors, new_vector)
        end
    end
    
    return result_vectors
end

function aspire(solution::TabuResult, s_best::TabuResult, aspiration_level::Float64 =0.05)::Bool
    if solution.cost < s_best.cost
        return true
    end
    
    # It might be close enough to the best solution to be accepted
    relative_improvement = (s_best.cost - solution.cost) / s_best.cost
    if relative_improvement > -aspiration_level  # e.g. 0.05 for 5% difference
        return true
    end
    
    return false
end

