# Simulated Annealing

There are two things going on here. The first is a nice, general implementation of the simulated annealing stochastic search process in pure Ruby. The file simulated_annealing.rb should be useful in a wide number of problem domains, provided you format things as a simulated annealing problem. The second is a specific implementation of simulated annealing for a specific problem domain: scheduling a tournament. In this case, we're scheduling a debate tournament. The algorithm lets you specify different 'weights' to put on different undesirable properties of schedules, and then it searches for the most optimal schedule. This turns out to be a remarkably flexible way to schedule tournaments. Here's a breakdown of the files provided:

## debate_scheduler_ui.js

A Google spreadsheet is used as the user interface for the scheduler. You can make a copy of the spreadsheet [here](https://spreadsheets0.google.com/ccc?authkey=CIjQTA&hl=en&key=tyewGj8vrB1JYkuAr9FZJtg&hl=en&authkey=CIjQTA#gid=0)

(Go to File > Make a copy)

The code in this file is Google Apps Script, server-side JavaScript that interacts with the scheduler. The scheduler runs as a web server, so in order to try out the user interface, you do need to be able to run an Internet-facing webserver. Google Spreadsheets then communicates with the scheduler over HTTP to schedule the tournament. To make this work, you need to modify the SERVER variable at the top of the script (Tools > Scripts > Script editor in Google Spreadsheets) to point to your webserver. Assuming this is all done correctly, you should be able to go to Tournament > Generate Next Round in the spreadsheet and it will use simulated annealing to schedule the next round.

## debate_server.rb

This file implements the web server mentioned above. It's a simple Sinatra server implementation. All you need to do is run it somewhere where Google is able to see it. To do so, issue the command "ruby debate_server.rb". You'll need the 'sinatra' and 'json' ruby gems installed.

## debate_model.rb

This file implements the model objects for the simulated annealing algorithm. It shows how to implement the important methods that the simulated annealing algorithm expects, such as 'neighbor' and 'energy'.

## simulate_annealing.rb

This is the actual implementation of the simulated annealing algorithm. There are some constants at the top, but these are mostly just default values (exept for DEBUG, set this to false to get the algorithm to stop writing to stdout). The whole thing is endlessly configurable, and there's really no way to figure out the right parameters without experimentation. Simulated annealing is tricky business!

## License

Public domain. See the file UNLICENSE for details.
Some code taken from the Google Apps Script documentation is copyright Google Inc.
