CXX=g++
CC=g++
CFLAGS=-O3 -Wall -I../shared
CXXFLAGS=$(CFLAGS)
LDFLAGS=-lSDL -L. -lccvt

OBJECTS=ipclient.o udp_connection.o utils.o


all: init ipclient

init:
	ln -sf ../shared/* .

ipclient: $(OBJECTS)
	$(CXX) $(OBJECTS) $(LDFLAGS) -o ipclient

deps:
	$(CXX) -MM *.c *.cpp  $(CFLAGS) > .deps

include .deps

.PHONY: clean deps

clean:
	rm -f $(OBJECTS) ipclient

