CC	= gcc
INC_DIR = ../include
DEBUG   = DEBUG_NONE
CFLAGS	= -I $(INC_DIR) `pkg-config --cflags` -DDEBUG=$(DEBUG) 
LIBS	= `pkg-config --libs`

EXECUTABLES = beatTracking

all: $(EXECUTABLES)
	cp $^ ../bin

beatTracking: beatTracking.o tcp_connection.o #netimage.o cvutil.o
	$(CC) $(CFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

clean:
	rm -f *.o $(EXECUTABLES)

distclean: clean

.PHONY: clean
