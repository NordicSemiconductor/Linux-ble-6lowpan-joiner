# Makefile for OpenWRT package building.

all:
	$(CC) $(CFLAGS) src/bluetooth_6lowpand.c -o src/bluetooth_6lowpand $(LDFLAGS)

