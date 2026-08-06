PREFIX ?= /usr/local

pomo: pomo.swift
	swiftc -O pomo.swift -o pomo

.PHONY: install clean

install: pomo
	install -d $(PREFIX)/bin
	install pomo $(PREFIX)/bin/pomo

clean:
	rm -f pomo
