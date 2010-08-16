/***************************************************************************
 * udp_connection.h: UDP support functions
 * 
 * Author : Andreas Agne <agne@upb.de>
 * Created: 2006
 * -------------------------------------------------------------------------
 * Major Changes:
 * 
 * ??.??.2006	Andreas Agne	File created
 * *************************************************************************/
#ifndef UDP_CONNECTION_H
#define UDP_CONNECTION_H

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

//#define DGRAM_SIZE 1024	// now in global.h

struct udp_connection
{
	int local_fd;
	struct sockaddr_in remote_addr;
};

struct udp_connection * udp_connection_create(in_addr_t remote);
void udp_connection_free(struct udp_connection * con);

int udp_connection_send(struct udp_connection * con, unsigned char * buf, size_t len);
int udp_connection_recv(struct udp_connection * con, unsigned char * buf, size_t len); 

#endif // UDP_CONNECTION

