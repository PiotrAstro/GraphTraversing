const COMPANY = 2
const LINE = 3
const DEPARTURE_TIME = 4
const ARRIVAL_TIME = 5
const START_STOP = 6
const END_STOP = 7
const START_STOP_LAT = 8
const START_STOP_LON = 9
const END_STOP_LAT = 10
const END_STOP_LON = 11

const SAME_LINE_TIME_THRESHOLD = 2

function str_to_minutes(time::AbstractString)::Int
    minutes = 0
    splitted = split(time, ":")
    minutes += parse(Int, splitted[1]) * 60
    minutes += parse(Int, splitted[2])
    return minutes
end

function construct_graph(csv_path::String)::Dict{Symbol, Node}
    # Read the csv file with DataFrames
    df = CSV.read(csv_path, DataFrames.DataFrame)

    graph = Dict{Symbol, Node}()
    previous_arrival::Int = 0
    previous_stop::Symbol = Symbol("")
    course::Union{Course, Nothing} = nothing
    # Add the nodes
    for row in eachrow(df)
        company = Symbol(row[COMPANY])
        line = Symbol(row[LINE])
        departure_time = str_to_minutes(row[DEPARTURE_TIME])
        arrival_time = str_to_minutes(row[ARRIVAL_TIME])
        start_stop = Symbol(row[START_STOP])
        end_stop = Symbol(row[END_STOP])
        start_stop_lat = row[START_STOP_LAT]
        start_stop_lon = row[START_STOP_LON]
        end_stop_lat = row[END_STOP_LAT]
        end_stop_lon = row[END_STOP_LON]

        if isnothing(course)
            course = Course(line=line, id=1)
        elseif (
            course.line != line
            || previous_stop != start_stop
            || mod(departure_time - previous_arrival, MINUTES_PER_DAY) > SAME_LINE_TIME_THRESHOLD
            )
            course_id_next = course.id + 1
            course = Course(line=line, id=course_id_next)
        end

        node_from = get!(graph, start_stop, Node(name=start_stop, longitude=start_stop_lon, latitude=start_stop_lat))
        node_to = get!(graph, end_stop, Node(name=end_stop, longitude=end_stop_lon, latitude=end_stop_lat))

        ride = Ride(from_node=node_from, to_node=node_to, start_time=departure_time, end_time=arrival_time, course=course)
        ride_vector = get!(node_from.connections, node_to, Vector{Ride}())
        push!(ride_vector, ride)
        push!(course.rides, ride)

        previous_arrival = arrival_time
        previous_stop = end_stop
    end

    return graph
end

function construct_changes_graph(graph::Dict{Symbol, Node}) :: Dict{Symbol, NodeByChanges}
    graph_changes = Dict{Symbol, NodeByChanges}()
    for (stop, node) in graph
        node_changes = NodeByChanges(node=node)
        graph_changes[stop] = node_changes
    end

    for node_change in values(graph_changes)
        for node in keys(node_change.node.connections)
            node_change_to = graph_changes[node.name]
            if !(node_change_to in node_change.nodes_changes_to)
                push!(node_change.nodes_changes_to, node_change_to)
            end
        end
    end

    return graph_changes
end

function construct_time_graph(graph::Dict{Symbol, Node}) :: Dict{Symbol, NodeByTime}
    graph_time = Dict{Symbol, NodeByTime}()
    for (stop, node) in graph
        node_time = NodeByTime(node=node)
        graph_time[stop] = node_time
    end

    for node_time in values(graph_time)
        for node in keys(node_time.node.connections)
            node_time_to = graph_time[node.name]
            if !(node_time_to in node_time.nodes_time_to)
                push!(node_time.nodes_time_to, node_time_to)
            end
        end
    end

    return graph_time
end