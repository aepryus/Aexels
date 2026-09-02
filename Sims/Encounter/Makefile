CC ?= cc
CFLAGS = -O2 -Wall
ENGINE = ../../Source/Engines/Hyle/Philippine
SEA = ../../Source/Engines/Sea

encounter: encounter.c $(ENGINE)/Philippine.c $(ENGINE)/Philippine.h
	$(CC) $(CFLAGS) -I$(ENGINE) -I$(SEA) -o $@ encounter.c $(ENGINE)/Philippine.c -lm

run: encounter
	./encounter

clean:
	rm -f encounter

.PHONY: run clean
