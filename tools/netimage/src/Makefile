CC	= gcc
INC_DIR = ../include
DEBUG   = DEBUG_NONE
CFLAGS	= -I $(INC_DIR) `pkg-config --cflags opencv` -DDEBUG=$(DEBUG) 
LIBS	= `pkg-config --libs opencv`

EXECUTABLES = camgrab sendvideo recvvideo

all: $(EXECUTABLES)
	cp $^ ../bin

camgrab: camgrab.o cvutil.o
	$(CC) $(CFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

sendvideo: sendvideo.o tcp_connection.o netimage.o cvutil.o
	$(CC) $(CFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

recvvideo: recvvideo.o tcp_connection.o netimage.o cvutil.o
	$(CC) $(CFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

clean:
	rm -f *.o $(EXECUTABLES)

distclean: clean

.PHONY: clean
