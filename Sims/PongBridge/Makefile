CC ?= cc
CFLAGS = -O2 -Wall

pongbridge: pongbridge.c
	$(CC) $(CFLAGS) -o $@ $< -lm

run: pongbridge
	./pongbridge

snapshot: pongbridge
	./pongbridge snapshot

clean:
	rm -f pongbridge pongbridge_snapshot.svg

.PHONY: run snapshot clean
