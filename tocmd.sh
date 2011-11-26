#!/bin/bash
# used to shut up git send-email prompting about what addresses the
# messages should be sent to.

egrep '^To: ' $* | sed 's/^To: //' | sed 's/, /\n/'
