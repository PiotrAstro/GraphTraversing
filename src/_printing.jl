function time_to_string(time::Integer)::String
    time_normalized = time % MINUTES_PER_DAY
    hours = time_normalized ÷ 60
    minutes = time % 60
    return Printf.@sprintf("%02d:%02d", hours, minutes)
end

function print_path(path::Vector{Ride})
    by_courses = Dict{Course, Vector{Ride}}()
    course_order = Course[]
    
    for ride in path
        if !haskey(by_courses, ride.course)
            push!(course_order, ride.course)
        end
        vector = get!(by_courses, ride.course, Ride[])
        push!(vector, ride)
    end

    println("Path:")
    for course in course_order
        rides = by_courses[course]
        println("line ", course.line, " from \"", rides[1].from_node.name, "\" at ", time_to_string(rides[1].start_time), " to \"", rides[end].to_node.name, "\" at ", time_to_string(rides[end].end_time))
    end
end