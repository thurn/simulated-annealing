#!/usr/bin/env ruby
# An example implementation of classes that can use the simulated annealing 
# interface. Specifically, implements a data model for scheduling a debate
# tournament.

require 'rubygems'
require 'json'

# Represents a team participating in the tournament
class Team
  attr_reader :school
  attr_accessor :num_wins, :members, :name

  # Constructs a new Team.
  # 
  # Arguments:
  # school: The name of the team's school
  # members: The names of the members of the team
  # name: The name of the team
  # num_wins: The number of times this team has won a match. Defaults to 0.
  def initialize(school, members, name, num_wins=0)
    @school = school
    @members = members
    @name = name
    @num_wins = num_wins
  end

  # Returns:
  # A string representation of this team.
  def to_s()
    "#{@name} (#{@num_wins})"
  end

  # Returns:
  # A deep copy of this team.
  def clone()
    Team.new(@school.clone, @members.map {|m| m.clone}, @name.clone, @num_wins)
  end

  alias :inspect :to_s

end

# Represents a judge participating in this tournament.
class Judge
  attr_reader :school, :name

  # Constructs a new Judge object.
  # 
  # Arguments:
  # school: The name of the school which this judge is from
  # name: The judge's name
  def initialize(school, name)
    @school = school
    @name = name
  end

  # Returns:
  # A string representation of this judge.
  def to_s()
    @school
  end

  # Returns:
  # A deep copy of this judge.
  def clone()
    Judge.new(@school.clone, @name.clone)
  end

  alias :inspect :to_s

end

# Represents a match between two teams in the tournament with an arbitrary
# number of judges.
class Match
  attr_accessor :team_a, :team_b, :judges

  # Constructs a new Match object.
  #
  # Arguments:
  # team_a: The first of the two teams in this match
  # team_b: The second of the two teams in this match
  # judges: An array of the judges in this match
  def initialize(team_a, team_b, judges)
    @team_a = team_a
    @team_b = team_b
    @judges = judges
  end

  # Returns:
  # A string representation of this match.
  def to_s()
    "#{@team_a} vs #{@team_b}: #{@judges.join(" ")}"
  end

  # Returns:
  # A JSON representation of this match.
  def to_json()
    {
     "teamA" => @team_a.name,
     "teamB" => @team_b.name,
     "judges" => (@judges.map {|j| j.name}).join(", ")
    }
  end

  alias :inspect :to_s

  # Returns:
  # A random judge from this match.
  def random_judge()
    @judges[rand(@judges.length)]
  end

  # Returns:
  # A random team from this match.
  def random_team()
    return @team_a if rand > 0.5
    @team_b
  end

  # Returns:
  # A deep copy of this match.
  def clone()
    Match.new(@team_a.clone, @team_b.clone, @judges.map {|j| j.clone})
  end
end

# Represents a possible tournament schedule for a specific tournament round.
class Schedule
  attr_reader :matches

  # Create a new schedule. Pass in a list of matches in the schedule along with
  # a hash of penalties indicating a number that should be deducted from the
  # energy of a schedule whenever the specified undesirable situation occurs.
  # 
  # Valid Penalty Options:
  # teams_same_school: The two teams in a match are from the same school.
  # judge_same_school: A judge is from the same school as a team.
  # different_win_loss: The two teams have a different win/loss record.
  # 
  # Arguments:
  # matches: The matches in this tournament
  # penalties: The penalties to assign to clculate the "energy" of this schedule
  def initialize(matches, penalties)
    @matches = matches
    @penalties = penalties.freeze
  end

  # Returns:
  # A string representation of this schedule.
  def to_s
    @matches.join("\n")
  end

  # Returns:
  # A JSON representation of this schedule.
  def to_json
    (@matches.map {|m| m.to_json}).to_json
  end

  alias :inspect :to_s

  # Computes the energy of this schedule based on the penalties set up during
  # initialization. A higher energy is better. Energy corresponds to the 
  # 'fitness' of the tournament schedule, or how 'good' it is.
  #
  # Returns:
  # The energy of the current schedule
  def energy()
    score = 0
    @matches.each do |m|
      # Teams Same School
      if m.team_a.school == m.team_b.school
        score -= @penalties[:teams_same_school]
      end
      # Judges Same School
      m.judges.each do |j|
        if j.school == m.team_a.school
          score -= @penalties[:judge_same_school]
        end
        if j.school == m.team_b.school
          score -= @penalties[:judge_same_school]
        end
      end
      # Different Win/Loss
      if m.team_a.num_wins != m.team_b.num_wins
        score -= (1 + @penalties[:different_win_loss]) **
                 (m.team_a.num_wins - m.team_b.num_wins).abs
        score -= 1 # No, really, this makes sense...
      end
    end
    score
  end

  # Returns:
  # A deep copy of this schedule.
  def clone()
    Schedule.new(@matches.map {|m| m.clone}, @penalties)
  end

  # Invokes each of the functions passed into it in turn, computing the energy 
  # level after each function and then invoking the function again to reverse
  # its effects. Finally, invokes the function which caused the best energy 
  # state of the ones passed in.
  #
  # Arguments:
  # functions: An array of symbols corresponding to method names to invoke in
  #     sequence. Invoking any argument method a second time should reverse
  #     its effects.
  # args: The arguments to pass to each function.
  def find_best_permutation(functions, *args)
    scores = []
    functions.each_with_index do |fn, idx|
      method(fn).call(*args) # Permute on first call
      scores[idx] = [energy(), fn]
      method(fn).call(*args) # Reverse permutation on second call
    end
    best_fn = scores.shuffle.max_by {|x| x[0]}
    method(best_fn[1]).call(*args)
  end

  # Finds a "neighboring" schedule to the current schedule. Accomplishes this 
  # by checking each of the four permutation_ methods to see which one produces
  # the best resulting state (in terms of energy) and then destructively
  # modifies this Schedule to correspond to the best state found.
  # 
  # Returns:
  # This Schedule object modified to be in a new configuration.
  def neighbor()
    m1 = random_match
    m2 = random_match
    find_best_permutation([:permutation_one, :permutation_two,
                           :permutation_three, :permutation_four],
                          m1, m2)
    self
  end

  # Generates a new completely random schedule object from the supplied
  # arguments.
  #  
  # Arguments
  # teams: The teams taking place in the round being scheduled.
  # judges: The judges taking place in the round being scheduled.
  # penalties: The penalties for the round being scheduled, as described under
  #     the initialize method. 
  #
  # Returns:
  # A new, randomized Schedule object
  def Schedule.random_schedule(teams, judges, penalties)
    teams = teams.shuffle
    judges = judges.shuffle
    num_matches = teams.size / 2
    matches = []

    num_matches.times do
      team_a = teams.pop
      team_b = teams.pop
      matches << Match.new(team_a, team_b, [])
    end
    
    # Loop through the available judges putting them into matches evenly
    # until no judges are left
    catch (:done) do
      loop do
        matches.each do |match|
          throw :done if judges.empty?
          match.judges << judges.pop
        end 
      end
    end

    Schedule.new(matches, penalties)
  end

  # Construct a completely new random Schedule with the same matches and
  # penalties as this Schedule object.
  # 
  # Returns:
  # A new, random schedule based on this schedule.
  def shuffle()
    teams = []
    judges = []
    new_schedule = clone
    new_schedule.matches.each do |m|
      teams << m.team_a
      teams << m.team_b
      judges << m.judges
    end
    judges = judges.flatten
    penalties = @penalties
    Schedule.random_schedule(teams, judges, penalties)
  end

 private
  # Returns:
  # A randomly selected match from this Schedule
  def random_match()
    @matches[rand(@matches.length)]
  end
  
  # A permutation which swaps the teams in two matches
  def permutation_one(m1, m2)
    m1.team_a, m2.team_b = m2.team_b, m1.team_a
  end

  # A permutation which swaps the teams in two matches differently
  def permutation_two(m1, m2)
    m1.team_a, m2.team_a = m2.team_a, m1.team_a
  end

  # A permutation which swaps the judges in two matches
  def permutation_three(m1, m2)
    m1.judges, m2.judges = m2.judges, m1.judges
  end

  # A permutation which swaps the first judges in two matches
  def permutation_four(m1, m2)
    m1.judges[0], m2.judges[0] = m2.judges[0], m1.judges[0]
  end
end
