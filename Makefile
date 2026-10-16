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
	! ./rtcsleep -n 10s 2>/dev/null
	! ./rtcsleep -n 1x 2>/dev/null
	! ./rtcsleep -n 1h30 2>/dev/null
	! ./rtcsleep -n 1h2h 2>/dev/null
	! ./rtcsleep -n 30m1h 2>/dev/null
	! ./rtcsleep -n 13pm 2>/dev/null
	! ./rtcsleep -n 1000000000 2>/dev/null
	! ./rtcsleep -n 99999999999999999999d 2>/dev/null
	! ./rtcsleep -n -m bogus 1h 2>/dev/null
	! ./rtcsleep -n "yesterday" 2>/dev/null
	! ./rtcsleep >/dev/null 2>&1
	@echo "All tests passed."
