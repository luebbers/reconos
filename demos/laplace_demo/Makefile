all: sw

sw: client server

server:
	make -C sw/server
	
client:
	make -C sw/client

clean:
	make -C sw/server clean
	make -C sw/client clean

