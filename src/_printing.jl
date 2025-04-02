function time_to_string(time::Integer)::String
    time_normalized = time % MINUTES_PER_DAY
    hours = time_normalized ÷ 60
    minutes = time % 60
    return Printf.@sprintf("%02d:%02d", hours, minutes)
end

function minutes_to_string(minutes::Integer)::String
    hours = minutes ÷ 60
    minutes = minutes % 60
    return "$(hours)h $(minutes)min"
end

function print_path(result_path::ResultPath, ride_number::Union{Int, Nothing}=nothing)
    by_courses = Dict{Course, Vector{Ride}}()
    course_order = Course[]
    
    for ride in result_path.path
        if !haskey(by_courses, ride.course)
            push!(course_order, ride.course)
        end
        vector = get!(by_courses, ride.course, Ride[])
        push!(vector, ride)
    end

    add_text = isnothing(ride_number) ? "" : " $ride_number"
    println("Ride$add_text: $(result_path.path[1].from_node.name) -> $(result_path.path[end].to_node.name)")
    println("Cost: ", result_path.cost, " time: ", minutes_to_string(result_path.ride_time), " ", time_to_string(result_path.path[1].start_time), " -> ", time_to_string(result_path.path[end].end_time))
    for course in course_order
        rides = by_courses[course]
        println("\tline ", course.line, " from \"", rides[1].from_node.name, "\" at ", time_to_string(rides[1].start_time), " to \"", rides[end].to_node.name, "\" at ", time_to_string(rides[end].end_time))
    end
end

function print_tabu_result(tabu_result::TabuResult)
    println("Stops: ", join([String(stop) for stop in tabu_result.stops], ", "))
    println("Total Cost: ", tabu_result.cost, " total time: ", minutes_to_string(sum(x -> x.ride_time, tabu_result.result_vector)), " ", time_to_string(tabu_result.result_vector[1].path[1].start_time), " -> ", time_to_string(tabu_result.result_vector[end].path[end].end_time))
    println()
    for (i, ride) in enumerate(tabu_result.result_vector)
        print_path(ride, i)
    end
end

function get_user_stops(general_graph::Dict{Symbol, Node}, min_number_of_stops::Int=2)::Vector{Symbol}
    println("Enter the stops separated by semicolons:")
    while true
        print("\t>>> ")
        input = readline()
        stops = split(strip(input), ";")
        stops = [strip(stop) for stop in stops]
        if length(stops) < min_number_of_stops
            println("You need to enter at least $min_number_of_stops stops.")
            continue
        end

        stops_symbols = [Symbol(stop) for stop in stops]
        if all(stop -> haskey(general_graph, stop), stops_symbols)
            return stops_symbols
        end
        for stop in stops
            if !haskey(general_graph, Symbol(stop))
                println("Stop \"$stop\" does not exist.")
            end
        end
    end
end

function get_user_time()::Int
    println("Enter the time in format HH:MM")
    while true
        print("\t>>> ")
        input = readline()
        splitted = split(strip(input), ":")
        if length(splitted) != 2
            println("Invalid format. Please enter the time in format HH:MM.")
            continue
        end
        hours = parse(Int, splitted[1])
        minutes = parse(Int, splitted[2])
        if hours < 0 || hours > 23 || minutes < 0 || minutes > 59
            println("Invalid time. Please enter a valid time in format HH:MM.")
            continue
        end
        return hours * 60 + minutes
    end
end

function get_user_mode()::Symbol
    println("Enter the mode:")
    println("\t1 or \"time\" -> Optimize for time")
    println("\t2 or \"changes\" -> Optimize for number of changes")
    while true
        print("\t>>> ")
        input = strip(readline())
        if input == "time" || input == "1"
            return :time
        elseif input == "changes" || input == "2"
            return :changes
        end
        println("Invalid mode. Please enter either \"time\"/\"1\" or \"changes\"/\"2\".")
    end
end

function get_user_algorithm()::Function
    println("Enter the algorithm:")
    println("\t1 or \"dijkstra\" -> Dijkstra's algorithm")
    println("\t2 or \"a_star\" -> A* algorithm")
    while true
        print("\t>>> ")
        input = strip(readline())
        if input == "dijkstra" || input == "1"
            return dijkstra
        elseif input == "a_star" || input == "2"
            return a_star
        end
        println("Invalid algorithm. Please enter either \"dijkstra\"/\"1\" or \"a_star\"/\"2\".")
    end
end

function get_user_operation()::Symbol
    println("What would you like to do?")
    println("\t\"single\" -> Find a path")
    println("\t\"many\" -> Find multiple paths")
    println("\t\"exit\" -> end the programm")
    while true
        print("\t>>> ")
        input = strip(readline())
        
        if input == "1" || input == "single"
            return :single
        elseif input == "2" || input == "many"
            return :many
        elseif input == "3" || input == "exit"
            return :exit
        end

        println("Invalid operation - \"$input\". Try again.")
    end
end