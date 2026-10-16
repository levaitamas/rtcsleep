PREFIX ?= /usr/local
BINDIR ?= $(PREFIX)/bin

.PHONY: all install uninstall check lint test

all:
	@echo "Nothing to build. Targets: install, uninstall, check"

install:
	install -Dm755 rtcsleep $(DESTDIR)$(BINDIR)/rtcsleep

uninstall:
	rm -f $(DESTDIR)$(BINDIR)/rtcsleep

check: lint test

lint:
	shellcheck rtcsleep

# Dry-run smoke tests: no root, no alarm, no sleep.
test:
	./rtcsleep -h >/dev/null
	./rtcsleep -n 90
	./rtcsleep -n 1h30m
	./rtcsleep -n 1d12h
	./rtcsleep -n 1d2h3m4s
	./rtcsleep -n 07:00
	./rtcsleep -n 7am
	./rtcsleep -n 6:30pm
	./rtcsleep -n "7 PM"
	./rtcsleep -n "5pm tomorrow"
	./rtcsleep -n -m hibernate "tomorrow 6:30"
	./rtcsleep -n -m off 2h
	./rtcsleep -n " 08:00 "
	./rtcsleep -n 0000000090
	$(call rejects,10s,less than 30s)
	$(call rejects,1x,invalid duration)
	$(call rejects,1h30,invalid duration)
	$(call rejects,1h2h,invalid duration)
	$(call rejects,30m1h,invalid duration)
	$(call rejects,13pm,invalid time)
	$(call rejects,1000000000,too long)
	$(call rejects,99999999999999999999d,too long)
	$(call rejects,-m bogus 1h,invalid mode)
	$(call rejects,yesterday,in the past)
	$(call rejects,-m,needs an argument)
	$(call rejects,-x 1h,unknown option)
	./rtcsleep 2>&1 >/dev/null | grep -q '^Usage:'; ! ./rtcsleep >/dev/null 2>&1
	@echo "All tests passed."

# rejects(args, message): the dry run must fail and say why. Checking the
# message makes sure it failed for the expected reason, not from a crash.
rejects = ./rtcsleep -n $(1) 2>&1 | grep -q '^rtcsleep: .*$(2)' && ! ./rtcsleep -n $(1) >/dev/null 2>&1
