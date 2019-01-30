mutable struct Colonies
    lambda_station_trip::Array{Float64, 2}
    lambda_trip_station::Array{Float64, 2}
    nb_stations::Int # Number of stations in the bike-sharing system
    current_time::Float64 # Current time of the colonies process
    nb_bikes_station::Array{Int64, 1} # Number of bikes parked in station i
    nb_bikes_trip::Array{Int64, 2} # Number of bikes on the trip t_ij
end

Colonies(x, y) = Colonies(
    x,
    y,
    size(x)[1],
    -Inf,
    zeros(Int64, size(x)[1]),
    zeros(Int64, size(x)[1], size(x)[1])
)

function initialize!(
    col::Colonies,
    nb_bikes_station::Array{Int64, 1},
    nb_bikes_trip::Array{Int64, 2}
)
    col.nb_bikes_station::Array{Int64, 1} = deepcopy(nb_bikes_station)
    col.nb_bikes_trip::Array{Int64, 2} = deepcopy(nb_bikes_trip)
    col.current_time = 0.
end

function transition_station_trip!(col::Colonies, i::Int, j::Int)
    col.nb_bikes_station[i] -= 1
    col.nb_bikes_trip[i, j] += 1
end

function transition_trip_station!(col::Colonies, i::Int, j::Int)
    col.nb_bikes_trip[i, j] -= 1
    col.nb_bikes_station[j] += 1
end
