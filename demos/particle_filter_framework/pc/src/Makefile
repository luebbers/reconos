CC	= gcc
INC_DIR = ../include
DEBUG   = DEBUG_NONE
CFLAGS	= -I $(INC_DIR) `pkg-config --cflags opencv` -DDEBUG=$(DEBUG) 
LIBS	= `pkg-config --libs opencv`

EXECUTABLES = objectTracking

all: $(EXECUTABLES)
	cp $^ ../bin

objectTracking: objectTracking.o tcp_connection.o netimage.o cvutil.o
	$(CC) $(CFLAGS) $(INCLUDE) $(LIBS) $^ -o $@

clean:
	rm -f *.o $(EXECUTABLES)

distclean: clean

.PHONY: clean
