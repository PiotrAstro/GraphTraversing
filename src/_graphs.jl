import Base: ==, hash, iterate

#-------------------------------------------------------------
# Constants

const MINUTES_PER_DAY = 24 * 60

#-------------------------------------------------------------
# Data structures

@kwdef struct CourseInternal{R}
    line::Symbol
    id::Int
    rides::Vector{R} = Vector{R}()
end

hash(c::CourseInternal, h::UInt = zero(UInt)) = hash(c.id, h)
==(c1::CourseInternal, c2::CourseInternal) = c1.id == c2.id

@kwdef struct RideInternal{N}
    from_node::N
    to_node::N
    start_time::Int
    end_time::Int
    course::CourseInternal{RideInternal{N}}
end

==(r1::RideInternal, r2::RideInternal) = r1.course == r2.course && r1.start_time == r2.start_time && r1.end_time == r2.end_time

@kwdef struct Node
    name::Symbol
    longitude::Float32
    latitude::Float32
    connections::Dict{Node, Vector{RideInternal{Node}}} = Dict{Node, Vector{RideInternal{Node}}}()
end

const Ride = RideInternal{Node}
const Course = CourseInternal{Ride}

==(n1::Node, n2::Node) = n1.name == n2.name
hash(n::Node, h::UInt = zero(UInt)) = hash(n.name, h)

#-------------------------------------------------------------
# Interface
abstract type NodeOptimization end

function update!(node_from::NodeOptimization, node_to::NodeOptimization)::Bool
    throw(ArgumentError("Not implemented"))
end

function get_path(final_node::NodeOptimization, graph::Dict{Symbol})::Vector{Ride}
    throw(ArgumentError("Not implemented"))
end

function get_cost(node::NodeOptimization)::Float64
    throw(ArgumentError("Not implemented"))
end

function set_first_arrival_time!(node::NodeOptimization, time::Int)
    throw(ArgumentError("Not implemented"))
end

function get_neighbours(node::NodeOptimization)::Vector{NodeOptimization}
    throw(ArgumentError("Not implemented"))
end

function set_cost!(node::NodeOptimization, cost)
    throw(ArgumentError("Not implemented"))
end

function get_arrival_time(node::NodeOptimization)::Int
    throw(ArgumentError("Not implemented"))
end

function get_distance_kilometers(node1::NodeOptimization, node2::NodeOptimization)::Float64
    # Use direct field access for better performance
    lat1 = node1.node.latitude
    lon1 = node1.node.longitude
    lat2 = node2.node.latitude
    lon2 = node2.node.longitude
    
    # Earth's radius in kilometers
    R = 6371.0
    
    # Pre-compute values to avoid redundant calculations
    lat1_rad = deg2rad(lat1)
    lon1_rad = deg2rad(lon1)
    lat2_rad = deg2rad(lat2)
    lon2_rad = deg2rad(lon2)
    
    sin_lat = sin((lat2_rad - lat1_rad) / 2)
    sin_lon = sin((lon2_rad - lon1_rad) / 2)
    
    # Simplified Haversine calculation
    a = sin_lat^2 + cos(lat1_rad) * cos(lat2_rad) * sin_lon^2
    
    # Use sqrt(1-a) * sqrt(1-a) = 1-a for better numerical stability
    # This avoids an additional sqrt and atan2 call
    distance = 2 * R * asin(sqrt(a))
    
    return distance
end

#-------------------------------------------------------------
# Interface implementations

@kwdef mutable struct NodeByTime <: NodeOptimization
    const node::Node
    const nodes_time_to::Vector{NodeByTime} = Vector{NodeByTime}()
    arrival_time::Int = typemax(Int) ÷ 2
    arrival_ride::Union{Ride, Nothing} = nothing
end

==(n1::NodeByTime, n2::NodeByTime) = n1.node == n2.node
hash(n::NodeByTime, h::UInt = zero(UInt)) = hash(n.node, h)

@kwdef struct RideArrival
    ride::Ride
    arrival_time::Int
end

@kwdef mutable struct NodeByChanges <: NodeOptimization
    const node::Node
    const nodes_changes_to::Vector{NodeByChanges} = Vector{NodeByChanges}()
    min_node_arrival_time::Int = typemax(Int) ÷ 2
    changes_required::Int = typemax(Int) ÷ 2
    arrival_rides::Dict{Course, RideArrival} = Dict{Course, RideArrival}()
end

==(n1::NodeByChanges, n2::NodeByChanges) = n1.node == n2.node
hash(n::NodeByChanges, h::UInt = zero(UInt)) = hash(n.node, h)

#-------------------------------------------------------------
# General functions

function get_ride_and_waiting_time(ride::Ride, min_leave_time::Integer)
    leave_normalized = min_leave_time % MINUTES_PER_DAY
    
    ride_time = ifelse(ride.end_time < ride.start_time,
                      ride.end_time + MINUTES_PER_DAY - ride.start_time,
                      ride.end_time - ride.start_time)
    
    waiting_time = ifelse(ride.start_time < leave_normalized,
                         ride.start_time + MINUTES_PER_DAY - leave_normalized,
                         ride.start_time - leave_normalized)
    return ride_time + waiting_time
end


#-------------------------------------------------------------
# By time functions

"""
Return true if changed to node
"""
function update!(node_time_from::NodeByTime, node_time_to::NodeByTime)::Bool
    changed = false
    for ride in node_time_from.node.connections[node_time_to.node]
        ride_waiting_time = get_ride_and_waiting_time(ride, node_time_from.arrival_time)
        time_to_ride = node_time_from.arrival_time + ride_waiting_time
        
        if node_time_to.arrival_time > time_to_ride
            node_time_to.arrival_time = time_to_ride
            node_time_to.arrival_ride = ride
            changed = true
        elseif node_time_to.arrival_time == time_to_ride && !isnothing(node_time_from.arrival_ride) && node_time_from.arrival_ride.course == ride.course
            node_time_to.arrival_ride = ride
            changed = true
        end
    end

    return changed
end

function get_path(final_node::NodeByTime, graph::Dict{Symbol, NodeByTime})::Vector{Ride}
    path = Vector{Ride}()
    current_node = final_node
    while !isnothing(current_node.arrival_ride)
        ride = current_node.arrival_ride
        pushfirst!(path, ride)
        current_node = graph[ride.from_node.name]
    end
    return path
end

function get_cost(node::NodeByTime)::Float64
    return node.arrival_time
end

function set_first_arrival_time!(node::NodeByTime, time::Int)
    node.arrival_time = time
end

function get_neighbours(node::NodeByTime)::Vector{NodeByTime}
    return node.nodes_time_to
end

function set_cost!(node::NodeByTime, cost)
    node.arrival_time = cost
end

function get_arrival_time(node::NodeByTime)::Int
    return node.arrival_time
end

#-------------------------------------------------------------
# By changes functions

"""
Return true if changed line
"""
function get_ride_arrival(node_changes_from::NodeByChanges, ride::Ride)::Tuple{RideArrival, Bool}
    if haskey(node_changes_from.arrival_rides, ride.course)
        ride_arrival = node_changes_from.arrival_rides[ride.course]
        ride_waiting_time = get_ride_and_waiting_time(ride, ride_arrival.arrival_time)
        ride_arrival_time = ride_arrival.arrival_time + ride_waiting_time
        return RideArrival(ride, ride_arrival_time), false
    end

    ride_waiting_time = get_ride_and_waiting_time(ride, node_changes_from.min_node_arrival_time)
    ride_arrival_time = node_changes_from.min_node_arrival_time + ride_waiting_time
    return RideArrival(ride, ride_arrival_time), true
end

"""
Return true if changed to node
"""
function update!(node_changes_from::NodeByChanges, node_changes_to::NodeByChanges)::Bool
    changed = false
    for ride in node_changes_from.node.connections[node_changes_to.node]
        ride_arrival, change_required = get_ride_arrival(node_changes_from, ride)
        changes_to = node_changes_from.changes_required + change_required
        if changes_to < node_changes_to.changes_required
            node_changes_to.changes_required = changes_to
            empty!(node_changes_to.arrival_rides)
            node_changes_to.arrival_rides[ride.course] = ride_arrival
            node_changes_to.min_node_arrival_time = ride_arrival.arrival_time
            changed = true
        elseif changes_to == node_changes_to.changes_required
            if haskey(node_changes_to.arrival_rides, ride.course)
                ride_arrival_already = node_changes_to.arrival_rides[ride.course]
                if ride_arrival.arrival_time < ride_arrival_already.arrival_time
                    node_changes_to.arrival_rides[ride.course] = ride_arrival
                    changed = true
                end
            else
                node_changes_to.arrival_rides[ride.course] = ride_arrival
                changed = true
            end

            if ride_arrival.arrival_time < node_changes_to.min_node_arrival_time
                node_changes_to.min_node_arrival_time = ride_arrival.arrival_time
            end
        end
    end
    return changed
end

function get_most_appropriate_ride(node::NodeByChanges, current_course)::Ride
    if !isnothing(current_course)
        if haskey(node.arrival_rides, current_course)
            return node.arrival_rides[current_course].ride
        end
    end
    min_arrival_time_ride = argmin(ride -> ride.arrival_time, values(node.arrival_rides))
    return min_arrival_time_ride.ride
end

function get_path(final_node::NodeByChanges, graph::Dict{Symbol, NodeByChanges})::Vector{Ride}
    path = Vector{Ride}()
    current_node = final_node
    current_course = nothing
    while !isempty(current_node.arrival_rides)
        best_ride = get_most_appropriate_ride(current_node, current_course)
        pushfirst!(path, best_ride)
        current_course = best_ride.course
        current_node = graph[best_ride.from_node.name]
    end
    return path
end

function get_cost(node::NodeByChanges)::Float64
    return Float64(node.changes_required) + Float64(node.min_node_arrival_time) / 1_000_000.0
end

function special_cost(node::NodeByChanges)::Float64
    return Float64(node.changes_required) + Float64(node.min_node_arrival_time) / 60.0
end

function set_cost!(node::NodeByChanges, cost)
    node.changes_required = cost
end

function set_first_arrival_time!(node::NodeByChanges, time::Int)
    node.min_node_arrival_time = time
end

function get_neighbours(node::NodeByChanges)::Vector{NodeByChanges}
    return node.nodes_changes_to
end

function get_arrival_time(node::NodeByChanges)::Int
    return node.min_node_arrival_time
end
