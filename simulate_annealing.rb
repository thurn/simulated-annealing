# Implements the general Simulated Annealing algorithm in Ruby
# Author(s): Derek Thurn

MAX_TIME = 1000
MAX_ENERGY = 0

# If temperature is not specified, just use the inverse of time
def default_temperature_fn(time)
  MAX_TIME - time
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
#
# initial_state: The initial state to the simulation. States must define two
#     methods: 1) neighbor(), a method which returns a neighboring state to
#     the state and 2) energy(), a method which returns the energy of a state
# max_time: The maximum number of steps to run the simulation for. Defaults to
#     1000 if not specified
# max_energy: The target energy value for the simulation. Defaults to 0 if not
#     specified.
# temperature: A function which takes as input a number of steps into the
#     simulation and returns the current temperature after that number of steps.
#     Defaults to default_temperature_fn if not specified.
# transition_probability: A function which takes the energy of the current
#     state, the energy of a proposed new state, and the current temperature,
#     and returns the probability that a transition to the new state will
#     occur. Defaults to default_transition_fn if not specified.
#
# Returns:
#
# The best (highest energy) state that the simulate was able to find
def simulate_annealing(initial_state, max_time=MAX_TIME, max_energy=MAX_ENERGY,
    temperature=method(:default_temperature_fn),
    transition_probability=method(:default_transition_fn))

  current_state = initial_state
  current_energy = current_state.energy()
  best_state = current_state
  best_energy = current_energy
  current_time = 0

  while current_time < max_time and current_energy < max_energy
    new_state = current_state.neighbor()
    new_energy = new_state.energy()
    tmp = temperature.call(current_time/max_time)
    if transition_probability.call(current_energy, new_energy, tmp) > rand()
      current_state = new_state
      current_energy = new_energy
    end
    if new_energy > best_energy
      best_state = new_state
      best_energy = new_energy
    end
    current_time += 1
  end

  best_state
end