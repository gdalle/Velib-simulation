tmi = typemax(Int64)

nb_stations = 5

## TRANSITION RATES

# Average trip duration from i to j [min]
tau = [
    [tmi  3    5    7    7];
    [2    tmi  2    5    5];
    [4    2    tmi  3    3];
    [8    6    4    tmi  2];
    [7    7    5    2    tmi]]

# Rate of transition from t_ij to j [min^-1]
lambda_trip_station = 1 ./ tau

# Frequency of bike departures for each station [min^-1]
departures = [2.8,  3.7,  5.5,  3.5,  4.6] ./ 60

# Probability that a bike will leave from station i to station j
routing = [
    [0      0.22 	0.32 	0.2	    0.26];
    [0.17 	0       0.34 	0.21 	0.28];
    [0.19 	0.26 	0       0.24 	0.31];
    [0.17 	0.22 	0.33 	0       0.28];
    [0.18 	0.24 	0.35 	0.23    0]]

# Rate of transition from i to t_ij [min^-1]
lambda_station_trip = departures .* routing

## INITIAL VALUES

# Number of bikes parked in station i
nb_bikes_station = [20,  16,  17,  13,  18]

# Number of bikes on the trip t_ij
nb_bikes_trip = [
    [0  1  0  0  0];
    [1  0  1  0  0];
    [0  1  0  1  0];
    [0  0  1  0  1];
    [0  0  0  1  0];
    ]

function define_random_initial_conditions()

    # Here we simulate random initial conditions

    number_of_bikes = 20+16+17+13+18+8
    nb_bikes_station = Array{Int64, 1}(undef, 0)
    nb_bikes_trip = [rand(0:2) for _ in 1:nb_stations, _ in 1:nb_stations]
    for i in 1:nb_stations
        nb_bikes_trip[i, i] = 0
        push!(nb_bikes_station, rand(1:number_of_bikes))
    end
    while sum(nb_bikes_station) != number_of_bikes-sum(nb_bikes_trip)
        station = rand(1:nb_stations)
        if nb_bikes_station[station] > 0
            nb_bikes_station[station] -= 1
        end
    end
    # Number of bikes on the trip t_ij
    
    return nb_bikes_station, nb_bikes_trip
end
