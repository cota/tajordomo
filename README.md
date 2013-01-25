# tajordomo
### the stupid assistant for lazy Teaching Assistants

## Description

tajordomo is designed to automate as much as possible the management
of a course. Particular emphasis is on:

* Scriptability.
* Automated creation of student teams.
  Students register their teams via email, and then tajordomo
  extracts the list of team members from the emails received.
* Intuitive student/team querying.
* Mass communication with students. Once a tajordomo repository is
  built, sending email to students/teams is very easy.
* Efficient grading, which allows the grader to use a common rubric
  (with deductions that apply equally to all students) while also entering
  specific comments on each review. Statistics' extraction also available.
* Grade communication. Grades can be easily sent via email and also
  exported to CSV.

## Usage

$ tajordomo --help

    Usage:  tajordomo [sub-command] [options]
   
    The following built-in subcommands are available; they should all respond to
    '-h' or '--help' if you want further details:
    
        init                        1st run: initial setup
        grades                      Export grades or generate statistics about them
        list                        Query the student/team library
        send-email                  Send email to students/teams
        teams                       Create teams


## Tutorial

### Initialise a tajordomo repository
    ~/foo$ tajordomo init .
    Initialised tajordomo repository at ./.tajordomo
    ~/foo$ ls .tajordomo/
    config

### Create a list of users

    ~/foo$ cat .tajordomo/users
    ww1270	William	Wallace	ww1270@foma.edu
    sp1605	Sancho	Panza	sp1605@foma.edu
    hd1797	Humpty	Dumpty	hd1797@foma.edu

### Query the list of users/teams

List all:

    ~/foo$ tajordomo list
    sp1605, Sancho Panza, sp1605@foma.edu, (orphan)
    ww1270, William Wallace, ww1270@foma.edu, (orphan)
    hd1797, Humpty Dumpty, hd1797@foma.edu, (orphan)

String search:

    ~/foo$ tajordomo list Panza
    sp1605, Sancho Panza, sp1605@foma.edu, (orphan)

### Automatically create teams from registration emails

Sample email body:

    We have a two-person team. One of the members is Sancho Panza whose
    id is sp1605, and the other is Humpty Dumpty, hd1797.

tajordomo parses the registration emails and creates the teams, assigning
a unique teamid to each of them:

    ~/foo$ tajordomo teams create ~/bar.mbox
    Added 2 team(s).
    ~/foo$ cat .tajordomo/teams
    1: ww1270
    2: sp1605, hd1797
    ~/foo$ tajordomo list
    sp1605, Sancho Panza, sp1605@foma.edu, (team 2)
    ww1270, William Wallace, ww1270@foma.edu, (team 1)
    hd1797, Humpty Dumpty, hd1797@foma.edu, (team 2)
    ~/foo$ tajordomo list 'team 2'
    sp1605, Sancho Panza, sp1605@foma.edu, (team 2)
    hd1797, Humpty Dumpty, hd1797@foma.edu, (team 2)

Note: users without a team can be listed by entering 'orphan' as the
      query string.

### Communicate with your users/teams

For instance, to send a reminder to students who did not send a registration
email:

    ~/foo$ cat notreg.msg
    Subject: Course Registration Closed

    Hi $NAMES,

    We have not yet received an email from you or your teammate (if any)
    to register as a team for the course.

    Please send the registration email as described in the course
    instructions as soon as possible.
    ~/foo$ tajordomo send-email --user --template notreg.msg 'orphan'

The ones who did register should receive their team ID via email:

    ~/foo$ cat reg.msg
    Subject: [csee4824] Course team info: team $TEAM
    
    Hi $NAMES,
    
    You have been assigned team number $TEAM for the course. Remember to
    use this team id in all submissions for this course.
    ~/foo$ tajordomo send-email --team --template reg.msg 'team'

### Grade their work
Each submission gets a YAML file which contains the grade. The amount of
information included here is optional; you may just give them a numeric
grade with or without further explanation, or may let tajordomo apply deductions
from a well-defined rubric. The latter case, since is the most complex,
is explained here:

First, the rubric:

    ~/foo$ cat rubric.yaml
    # rubric for foo
    ---
    # max score for this assignment
    score: 220
    code:
      # how easy it is to understand, style issues, etc
      quality:
        max: 20
        deductions:
          noinline:
            t: The use of inlined functions would have avoided
               excessive line breaking in deeply nested code.
            v: -3
          minor:
            t: Minor formatting issues.
            v: -4
          major:
            t: Broken coding style.
            v: -10
    
      performance:
        max: 100
        deductions:
          notest:
            t: The final implementation does not pass `make test'.
            v: -50
          cowboy:
            t: Did not follow the instructions on how to build
               your own algorithms.
            v: -30
          nolooptiling:
            t: Did not try loop tiling, which is more efficient than transposing.
            v: -10
    
    report:
      quality:
        max: 100
        deductions:
          minorlang:
            t: Minor language issues.
            v: -10
          majorlang:
            t: The report was hard to follow; at times, language got on the
               way of understanding.
            v: -30
          coulddeeper:
            t: Could have analysed in more depth, but everything is covered.
            v: -15
          minimum:
            t: Minimum grade, very poor report.
            v: 25
    ...

Note the hierarchy in the rubric file. Sections can be arbitrarily nested,
although note that the grade files must follow the same hierarchy.
Each 'max' leaf of this tree contains the maximum grade for that subsection.
Deductions are then defined with text ("t") and numeric value ("v"). Deductions
are normally negative in value; however, sometimes it is convenient to just assign
a minimum grade to a given section -- in this case the value of the deduction
should be positive (see "report > quality > deductions > minimum" above).

Grade file for team1:

    ---
    team: 1
    code:
      quality:
        comm: perfect.
    
      performance:
        comm: $(notest) $(nolooptiling)
              I liked very much the transposing you did.
    
    report:
      quality:
        comm: $(coulddeeper) For instance, framing the discussion in terms
              of energy would have been more effective.
              Good report overall, with good references.
    ...

tajordomo will them match the deductions with those in the rubric, and
together with an email template we are ready to send each team their grade.
First though we can gather some statistics about how the students performed:

    $ tajordomo grades stats --rubric rubric.yaml grades/team*.yaml
    mean: 151.34
    stddev: 34.52
    median: 157.00
    histogram:
        65-94     ####
        94-123    #########
       123-152    ############
       152-181    ################
       181-210    ###############

And then we can include these stats in the email template:

    ~/foo$ cat graded.msg
    Subject: Assignment grade: team $TEAM
    
    Hi $NAMES,
    
    We have finished grading your assignment. Your results are as follows:
    
    - code quality:         ${code quality score} / 10
      ${code quality comm}
    
    - code performance:     ${code performance score} / 65
      ${code performance comm}
    
    - report quality:       ${report quality score} / 70
      ${report quality comm}
    
    TOTAL:                  ${total} / 220
    
    FYI, the mean for all submissions is 150.69 / 220, and the standard
    deviation is 34.49. Here is a histogram of the grades:
    
        65-94     ####
        94-123    #########
       123-152    ############
       152-181    ################
       181-210    ##############
    ~/foo$ tajordomo send-email --team --template graded.msg --grade grades/team1.yaml --autoformat --rubric rubric.yaml --confirm "(team 1)"

With the `--confirm` flag we can review the email body before deciding whether
to send it.

### Exporting grades to CSV for further processing
    ~/foo$ tajordomo grades csv --rubric rubric.yaml grades/*.yaml > foo.csv

## Config file

Note: The config file is a perl file, so keep that in mind when editing it.

Parameters:

* `ID_FORMAT`: Currently only "uni" is supported. You can add your own
  id format by creating a tiny module. See `lib/Tajordomo/Id/` for
  details.
* `INPUT_FORMAT`: How to interpret input files for extracting team information.
  Currently only "mbox_dir" is supported; see `lib/Tajordomo/Input/`
  for details.
* `EMAIL_FROM`: "From" field for outgoing email.
* `EMAIL_CC`: "Cc" field for outgoing email. Comma-separated addresses (e.g.
  "Foo Bar <foobar@2000.com>, Ba Boom <a@bc.com>") are fine here.
* `EMAIL_SMTP_OPTION`: tajordomo uses `git send-email` for sending email. The
  value string of this option is passed verbatim to `git send-email`.

## Dependences

* git (for sending email)
* Perl. CPAN packages: Term::Prompt, YAML::XS, Text::Autoformat,
  Text::CSV, Statistics::Descriptive.

## License
GPL v2.
