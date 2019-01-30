
include("colony.jl")

using StatsBase
using DataFrames
using Statistics
using ProgressMeter

"""
    Simulate the next transition of the Markov process.
"""
function simulate_next_transition(col::Colonies)
    # Compute current transition rates
    q_trip_station = col.lambda_trip_station .* col.nb_bikes_trip
    q_station_trip = col.lambda_station_trip .* convert(Array{Float64}, col.nb_bikes_station .> 0)

    # The sum of all transition rates defines the parameter of
    # the exponential distribution giving the time to the next transition
    total_transition_rate = sum(q_station_trip) + sum(q_trip_station)
    time_to_next_transition = -(1 / total_transition_rate) * log(rand())

    # Each transition has a likelihood that is proportional to its transition rate
    transitions = vcat(
        vec([(transition_type="station_trip", i=i, j=j) for i in 1:col.nb_stations, j in 1:col.nb_stations]),
        vec([(transition_type="trip_station", i=i, j=j) for i in 1:col.nb_stations, j in 1:col.nb_stations]),
    )
    transition_probas = vcat(
        vec([q_station_trip[i, j] / total_transition_rate for i in 1:col.nb_stations, j in 1:col.nb_stations]),
        vec([q_trip_station[i, j] / total_transition_rate for i in 1:col.nb_stations, j in 1:col.nb_stations])
    )

    # Sample a transition with the weights given above
    next_transition = sample(transitions, Weights(transition_probas))

    return next_transition, time_to_next_transition
end

"""
    Simulate a trajectory of the Markov process with a given initial repartition of bikes.
"""
function simulate(
        col::Colonies,
        max_time::Float64,
        nb_bikes_station::Array{Int64, 1},
        nb_bikes_trip::Array{Int64, 2}
    )

    col::Colonies = deepcopy(col)
    initialize!(col, nb_bikes_station, nb_bikes_trip)

    transitions_history = DataFrame(
        time = Float64[],
        transition_type = String[],
        i = Int64[],
        j = Int64[]
    )

    empty_station_duration = zeros(Float64, col.nb_stations)

    while col.current_time < max_time

        # Find the next transition
        next_transition, time_to_next_transition = simulate_next_transition(col)

        # If any station is empty, record the time it spent that way
        interval_duration = min(time_to_next_transition, max_time - col.current_time)
        for i in 1:col.nb_stations
            if col.nb_bikes_station[i] == 0
                empty_station_duration[i] += interval_duration
            end
        end

        if col.current_time + time_to_next_transition > max_time
            # The next transition will not have time to happen
            break
        end

        # Store the transition in the history log
        push!(transitions_history, (
            time = col.current_time + time_to_next_transition,
            transition_type = next_transition.transition_type,
            i = next_transition.i,
            j = next_transition.j
        ))

        # Perform the transition by modifying the Colonies object
        col.current_time += time_to_next_transition
        if next_transition.transition_type == "station_trip"
            transition_station_trip!(col, next_transition.i, next_transition.j)
        elseif next_transition.transition_type == "trip_station"
            transition_trip_station!(col, next_transition.i, next_transition.j)
        end

    end

    empty_station_duration ./= max_time

    return col, transitions_history, empty_station_duration
end

"""
    For each station, compute:
    - the frequency of emptiness at the end time
    - the mean duration spent empty
    over several trajectory simulated from the same initial state.
"""
function estimate_emptiness(
        col::Colonies,
        max_time::Float64,
        nb_simulations::Int64,
        nb_bikes_station::Array{Int64, 1},
        nb_bikes_trip::Array{Int64, 2}
    )

    empty_ends = zeros(nb_simulations, col.nb_stations)
    empty_durations = zeros(nb_simulations, col.nb_stations)

    @showprogress "Simulating trajectories " for sim in 1:nb_simulations

        new_col, transitions_history, empty_station_duration = simulate(
            col, max_time, nb_bikes_station, nb_bikes_trip)

        empty_ends[sim, :] = (new_col.nb_bikes_station .== 0)
        empty_durations[sim, :] = empty_station_duration

    end

    empty_end_freq = mean(empty_ends, dims=1)
    empty_end_freq_uncertainty = 1.96 * std(empty_ends, dims=1) / sqrt(nb_simulations)

    empty_duration_mean = mean(empty_durations, dims=1)
    empty_duration_mean_uncertainty = 1.96 * std(empty_durations, dims=1) / sqrt(nb_simulations)

    emptiness = DataFrame(
        empty_end_freq=empty_end_freq[:],
        empty_end_freq_uncertainty=empty_end_freq_uncertainty[:],
        empty_duration_mean=empty_duration_mean[:],
        empty_duration_mean_uncertainty=empty_duration_mean_uncertainty[:],
    )

    return emptiness
end

# Initial repartition of one bike, put arbitrarily in the first station
monobike_nb_bikes_station = zeros(Int64, 5)
monobike_nb_bikes_station[1] = 1
monobike_nb_bikes_trip = zeros(Int64, 5, 5)

"""
    For each station, compute:
    - the frequency of emptiness at the end time
    - the mean duration spent empty
    over several trajectores simulated from the monobike initial state.
"""
function estimate_emptiness_monobike(
        col::Colonies,
        max_time::Float64,
        nb_simulations::Int64,
    )
    return estimate_emptiness(
        col,
        max_time,
        nb_simulations,
        monobike_nb_bikes_station,
        monobike_nb_bikes_trip
    )
end
