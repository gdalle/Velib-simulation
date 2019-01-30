include("colony.jl")

"""
    Solve the traffic equations for the alpha_i with a linear system.
"""
function compute_alpha_station(col::Colonies)
    M = zeros(col.nb_stations, col.nb_stations)
    M[1, :] = ones(col.nb_stations)
    for i in 2:col.nb_stations, j in 1:col.nb_stations
        if i != j
            M[i, i] += col.lambda_station_trip[i, j]
            M[i, j] = - col.lambda_station_trip[j, i]
        end
    end

    b = zeros(col.nb_stations)
    b[1] = 1

    alpha_station = M \ b
    return alpha_station
end

"""
    Solve the traffic equations for the alpha_t_ij based on the alpha_i.
"""
function compute_alpha_trip(col::Colonies, alpha_station::Array{Float64, 1})
    alpha_trip = zeros(Float64, col.nb_stations, col.nb_stations)
    for i in 1:col.nb_stations, j in 1:col.nb_stations
        if i == j
            alpha_trip[i, i] = 0
        else
            alpha_trip[i, j] = alpha_station[i] * col.lambda_station_trip[i, j] / col.lambda_trip_station[i, j]
        end
    end
    return alpha_trip
end

"""
    Solve all the traffic equations.
"""
function compute_alpha(col::Colonies)
    alpha_station = compute_alpha_station(col)
    alpha_trip = compute_alpha_trip(col, alpha_station)
    return alpha_station, alpha_trip
end

"""
    Compute the stationary probability of emptiness with one bike.
"""
function emptiness_proba_monobike(
    alpha_station::Array{Float64, 1},
    alpha_bike::Array{Float64, 2}
)
    G_1 = sum(alpha_station) + sum(alpha_trip)
    emptiness_probability = 1 .- alpha_station / G_1
    return emptiness_probability
end
