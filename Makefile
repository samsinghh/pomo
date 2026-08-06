PREFIX ?= /usr/local

CLT := /Library/Developer/CommandLineTools
ifeq ($(shell xcode-select -p),$(CLT))
TEST_FLAGS := --disable-xctest \
	-Xswiftc -F -Xswiftc $(CLT)/Library/Developer/Frameworks \
	-Xlinker -F -Xlinker $(CLT)/Library/Developer/Frameworks \
	-Xlinker -rpath -Xlinker $(CLT)/Library/Developer/Frameworks \
	-Xlinker -rpath -Xlinker $(CLT)/Library/Developer/usr/lib
endif

.PHONY: all test install clean

all:
	swift build -c release

test:
	swift test $(TEST_FLAGS)

install: all
	install -d $(PREFIX)/bin
	install .build/release/pomo $(PREFIX)/bin/pomo

clean:
	rm -rf .build
