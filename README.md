# CS 3110 Final Project 

**Members:** Chris O'Brian (co253), Lorenzo Scotto di Vettimo (ls769), Radha Patel (rdp89)


## Installation Instructions
---
Our system requires the "Ocurl" package to function, to install, please run:

```
opam install ocurl
```

After which, you should run "make check" to ensure that your environment is what it should be. We've edited the checkenv.sh file to reflect our system.

Then, you can start our program by running "make run".

**NOTE:** You can always just press Enter/Return at the main prompt for info
on what possible commands can be used. Then, entering only that command with no
arguments will either execute the command (like "clear" or "quit"), or it will
provide info on what other arguments are required.

## Some example commands for MS1 functionality:

Initially, at the first prompt, type "new" to start a new schedule.

To create a new semester(s):
```
add FA19
add SP20
```

Add a new course:
(Here, 4 is # of credits, A- is grade, "CSCore" is degree catagory, FA19 is semester).
```
add CS3110 4 A- CScore FA19 
```

Add a new course (and have Class Roster get credits info):
```
add CS3410 B CScore FA19 
```

View Current Schedule:
```
print
```

Edit course attribute (like credits):
_Notice how GPA changes with this (by running print again)_
```
edit CS3110 credits 3
```

Remove a course:
```
remove CS3110
```

Remove a semester:
```
remove SP20
```

close:
```
quit
```

## Some example commands for MS2 functionality:

MS2 contains all of the same functionality as MS1, but the user now has the
ability to save a current schedule, load that schedule later, "close" the
current schedule, and export a schedule to an HTML file for visualization.

To start, again use "make run" to begin the initial prompt.

To make a new schedule:
```
new <schedule_name>
```

Or load a previously saved schedule:
```
load <filepath>.json
```

**NOTE:** We have included an _example.json_ file containing a schedule
already populated with some courses and semesters. Feel free to try loading and
working with it!

Once schedule is loaded or created, you'll be taken to the primary user prompt, where the
schedule name appears in green at the input line. New commands available are:

Saving a schedule:
_This command saves schedule as test.json in current working directory._
```
save test.json
```

Exporting a schedule to HTML:
_Exports HTML file to working directory._
```
export test.html
```

You can now open the html file in a web browser to see a nice visualization of
the schedule!

You can also close a current schedule to return to the initial prompt:
_Note: If you haven't saved your schedule it will prompt you to do so!_
```
close
```

A similar "save? prompt" will appear when you try to quit now!