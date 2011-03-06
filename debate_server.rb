#!/usr/bin/env ruby
# A simple Sinatra-based server which accepts tournament state descriptions 
# as POST in JSON format and returns a schedule (found through simulated 
# annealing) in JSON format

require 'rubygems'
require 'json'
require 'sinatra'
require 'debate_model'
require 'simulate_annealing'

# The URL to POST to in order to schedule a tournament. Arguments should be of
# the form:
# {
#   teams: [{speaker1:"", speaker2:"", teamName:"", teamSchool:"", numWins: 0}]
#   judges: [{judgeName:"", judgeSchool:""}]
#   penalties: [{penaltyName:"", penaltyValue:""}]
# }
#
# The response will be of the form:
# [{teamA:"", teamB:"", judges:""}]
post '/debate_schedule' do
  input = JSON.parse(request.body.string)

  # Populate teams from the JSON input
  teams = []
  input["teams"].each do |team|
    members = [team["speaker1"], team["speaker2"]]
    teams << Team.new(team["teamSchool"], members, team["teamName"], team["numWins"])
  end
  teams.freeze

  # Populate judges from the JSON input
  judges = []
  input["judges"].each do |judge|
    judges << Judge.new(judge["judgeSchool"], judge["judgeName"])
  end
  judges.freeze

  # Populate penalties from the JSON input
  penalties = {}
  input["penalties"].each do |penalty|
    penalties[penalty["penaltyName"].to_sym] = penalty["penaltyValue"].to_i
  end
  penalties.freeze

  # Schedule the tournament and return the result
  schedule = Schedule.random_schedule(teams, judges, penalties)
  best_schedule = simulate_annealing(schedule)
  [200, best_schedule.to_json]
end
