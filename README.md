# tajordomo
### the stupid assistant for lazy Teaching Assistants

## disclaimer
This is currently a WIP, and has embedded knowledge of my
academic environment--the most obvious being that students
are identified by a unique string called UNI.

## UNI
Each student has a unique UNI string. It can be matched with

    /[a-z]{2,3}[0-9]{4}/

## create_teams.pl
Processes an mbox file with messages from students, which they use to
describe their teams for a project. These messages typically are like:

    Date: Wed, 23 Nov 2011 17:07:32 -0500
    Subject: Computer Architecture
    From: XXXX <XXXX@foma.edu>
    To: project@foma.edu
    Cc: XXXX@foma.edu, YYYY <YYYY@foma.edu>

    XXXX: xx3203
    YYYY: yy2108

    We will be a team for the project.

    -XXXX

(See the UNI's?)
We use a pretty simple & stupid approach: just grep for UNI-like
substrings, and keep the ones that are in the list of students
taking this course (so that UNIs of other people in Cc do not
pollute the end result). Each email gets a new team ID.

### What if they sent repeated emails?
Remove those messages from the mbox. At the end of the day
you'll need to inspect those messages anyway, for the odd
"Please change me from my previous team, I'm now working
with ZZZ", so I figured it's safer to leave this extra work
to a human.

## Sending emails to the students
I use `git send-email` + `msmtp` for convenience, feel free to
choose some other combination. Mail is a can of worms so better
use an off-the-shelf solution.
