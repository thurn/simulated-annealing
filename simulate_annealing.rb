#!/usr/bin/env ruby
# Implements the general Simulated Annealing algorithm in Ruby

DEBUG=true
DEFAULT_RESTART_PROB=0.001
DEFAULT_MAX_TIME = 30000
DEFAULT_MAX_ENERGY = 0
DEFAULT_ALPHA = 0.95

# Creates a function to calculate temperature based on the default function
# form, T(k) = T0 * (alpha ** k), to use as a cooling schedule.
#
# Arguments:
# alpha: The cooling multiplier, 0 < alpha < 1. Should usually be quite close
#     to 1
#
# Returns:
# A temperature, 0 < temp < 1, for the supplied time period
def make_default_temp_fn(alpha)
  lambda { |time| (alpha ** time) }
end

# If no transition function is specified, use a default. Assumes that
# 0 < temp < 1 and works best when energies are confined to a range of size
# around 25.
#
# Arguments:
# e: The energy level of the current state
# e_prime: The energy level of the proposed new state
# temp: The current temperature, 0 < temp < 1.
#
# Returns:
# The probability that a transition will occur between the provided energy
# levels at the supplied temperature
def default_transition_fn(e, e_prime, temp)
  return 1 if e_prime > e
  Math.exp((e_prime-e) * (1.0 - temp))
end

# Performs the general Simulated Annealing algorithm.
#
# Arguments:
# initial_state: The initial state to the simulation. States must define two
#     methods: 1) neighbor(), a method which returns a neighboring state to
#     the state and 2) energy(), a method which returns the energy of a state.
#     The neighbor() method can mutate the state object, but then the state must
#     define a clone() method that produces a deep copy of the state. If the
#     restart_probability is non-zero, states must also define a shuffle()
#     method which produces an entirely random new state.
# restart_probability: The odds of jumping to a random state instead of a
#     neighbor at each step. Defaults to 0.001. Set to 0 to disable restarts.
# max_time: The maximum number of steps to run the simulation for. Defaults to
#     1000000 if not specified.
# max_energy: The target energy value for the simulation. Defaults to 0 if not
#     specified.
# temperature: A function which takes as input a number of steps into the
#     simulation and returns the current temperature after that number of steps.
#     Defaults to calling make_default_tmp_fn with alpha=0.95
# transition_probability: A function which takes the energy of the current
#     state, the energy of a proposed new state, and the current temperature,
#     and returns the probability that a transition to the new state will
#     occur. Defaults to default_transition_fn if not specified.
#
# Returns:
# The best (highest energy) state that the simulation was able to find
def simulate_annealing(initial_state,
    restart_probability=DEFAULT_RESTART_PROB,
    max_time=DEFAULT_MAX_TIME,
    max_energy=DEFAULT_MAX_ENERGY,
    temperature=make_default_temp_fn(DEFAULT_ALPHA),
    transition_probability=method(:default_transition_fn))

  # Initial simulation setup
  current_state = initial_state
  current_energy = current_state.energy
  best_state = current_state
  best_energy = current_energy
  current_time = 0 # time since last restart
  cumulative_time = 0 # overall time

  while cumulative_time < max_time and current_energy < max_energy

    new_state = if rand < restart_probability
      current_time = 0
      current_state.shuffle
    else
      current_state.neighbor
    end

    new_energy = new_state.energy
    tmp = temperature.call(current_time)

    # Check if we should transition
    if transition_probability.call(current_energy, new_energy, tmp) > rand
      current_state = new_state
      current_energy = new_energy
    end

    # Check if we have a new candidate solution
    if new_energy > best_energy
      best_state = new_state.clone
      best_energy = new_energy
    end

    current_time += 1
    cumulative_time += 1
  end

  if DEBUG
    puts "Final Time: #{cumulative_time}"
    puts "Final Energy: #{current_energy}"
  end

  best_state
end
