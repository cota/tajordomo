STUDENTS := students.txt
TEAMS := teams.txt

all: $(TEAMS)

send: $(TEAMS)
	./send.sh

$(TEAMS): messages.mbox
	./create_teams.pl --students=$(STUDENTS) $< > $@

clean:
	rm -rf team*.mail

mrproper: clean
	rm -rf $(TEAMS)

README.html: README.md
	markdown $< > $@

.PHONY: all send clean mrproper
