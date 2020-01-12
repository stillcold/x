#ifndef _EVENT_H
#define _EVENT_H

#include <stdint.h>
//sid == socket number, it will be remap in x_socket, not a real socket fd

typedef void (*x_finalizer_t)(void *ptr);


int x_socket_init();
void x_socket_exit();
void x_socket_terminate();

int x_socket_listen(const char *ip, const char *port, int backlog);
int x_socket_connect(const char *ip, const char *port,
		const char *bindip, const char *bindport);
int x_socket_udpbind(const char *ip, const char *port);
int x_socket_udpconnect(const char *ip, const char *port,
		const char *bindip, const char *bindport);
int x_socket_salen(const void *data);
const char *x_socket_ntop(const void *data, int *size);

int x_socket_send(int sid, uint8_t *buff, size_t sz,
	x_finalizer_t finalizer);
int x_socket_udpsend(int sid, uint8_t *buff, size_t sz,
	const uint8_t *addr, size_t addrlen, x_finalizer_t finalizer);
int x_socket_close(int sid);

int x_socket_poll();

const char *x_socket_pollapi();

#endif


