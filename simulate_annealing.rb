# Implements the general Simulated Annealing algorithm in Ruby
# Author(s): Derek Thurn

DEFAULT_MAX_TIME = 1000
DEFAULT_MAX_ENERGY = 0
DEFAULT_INITIAL_TEMP = 10000
DEFAULT_ALPHA = 0.99

# Creates a function to calculate temperature based on the default function
# form, T(k) = T0 * (alpha ** k), to use as a cooling schedule.
# Arguments:
# intial_temp: The initial temperature of the system
# alpha: The cooling multiplier, 0 < alpha < 1. Should usually be quite close
#     to 1
def make_default_temp_fn(initial_temp, alpha)
  lambda { |time| initial_temp * (alpha ** time) }
end

# If no transition function is specified, use the function given in the
# formulation by Kirkpatrick et al
def default_transition_fn(e, e_prime, t)
  return 1 if e_prime < e
  Math.exp((e - e_prime) / t)
end

# Performs the general Simulated Annealing algorithm.
#
# Arguments:
# initial_state: The initial state to the simulation. States must define two
#     methods: 1) neighbor(), a method which returns a neighboring state to
#     the state and 2) energy(), a method which returns the energy of a state
# max_time: The maximum number of steps to run the simulation for. Defaults to
#     1000 if not specified
# max_energy: The target energy value for the simulation. Defaults to 0 if not
#     specified.
# temperature: A function which takes as input a number of steps into the
#     simulation and returns the current temperature after that number of steps.
#     Defaults to calling make_default_tmp_fn with initial_temp=10,000 and
#     alpha = 0.99
# transition_probability: A function which takes the energy of the current
#     state, the energy of a proposed new state, and the current temperature,
#     and returns the probability that a transition to the new state will
#     occur. Defaults to default_transition_fn if not specified.
#
# Returns:
# The best (highest energy) state that the simulation was able to find
def simulate_annealing(initial_state,
    max_time=DEFAULT_MAX_TIME,
    max_energy=DEFAULT_MAX_ENERGY,
    temperature=make_default_temp_fn(DEFAULT_INITIAL_TEMP, DEFAULT_ALPHA),
    transition_probability=method(:default_transition_fn))

  # Initial simulation setup
  current_state = initial_state
  current_energy = current_state.energy()
  best_state = current_state
  best_energy = current_energy
  current_time = 0

  while current_time < max_time and current_energy < max_energy
    new_state = current_state.neighbor()
    new_energy = new_state.energy()
    tmp = temperature.call(current_time/max_time)

    # Check if we should transition
    if transition_probability.call(current_energy, new_energy, tmp) > rand()
      current_state = new_state
      current_energy = new_energy
    end

    # Check if we have a new candidate solution
    if new_energy > best_energy
      best_state = new_state
      best_energy = new_energy
    end

    current_time += 1
  end

  best_state
end