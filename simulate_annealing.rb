# Performs the general Simulated Annealing algorithm.
# Parameters
# initial_state: The initial state to the simulation
# max_time: The maximum number of steps to run the simulation for
# max_energy: The target energy value for the simulation
# neighbor: A function which takes a state and returns a neighboring state to
#     the supplied state
# get_energy: A function which takes a system state and evaluates it to
#     to determine its energy
# transition_probability: A function which takes the energy of the current
#     state, the energy of a proposed new state, and the current temperature,
#     and returns the probability that a transition to the new state will
#     occur
# temperature: A function which takes as input a number of steps into the
# simulation and returns the current temperature after that number of steps
def simulate_annealing(initial_state, max_time, max_energy, neighbor, get_energy,
    transition_probability, temperature)
  current_state = initial_state
  current_energy = get_energy.call(current_state)
  best_state = current_state
  best_energy = current_energy
  current_time = 0

  while current_time < max_time and current_energy < max_energy
    new_state = neighbor.call(current_state)
    new_energy = get_energy.call(new_state)
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