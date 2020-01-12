#ifndef _X_H
#define _X_H
#include <assert.h>
#include <stdint.h>
#include "x_conf.h"
#include "x_malloc.h"
#include "x_socket.h"

#define X_VERSION_MAJOR 0
#define X_VERSION_MINOR 3
#define X_VERSION_RELEASE 0
#define X_VERSION_NUM ((X_VERSION_MAJOR * 100) + X_VERSION_MINOR)
#define X_VERSION STR(X_VERSION_MAJOR) "." STR(X_VERSION_MINOR)
#define X_RELEASE X_VERSION "." STR(X_VERSION_RELEASE)


#define tocommon(msg)   ((struct x_message *)(msg))
#define totexpire(msg)  ((struct x_message_texpire *)(msg))
#define tosocket(msg)   ((struct x_message_socket *)(msg))
#define COMMONFIELD struct x_message *next; enum x_message_type type;

struct x_listen {
	char name[64];
	char addr[64];
};

struct x_config {
	int daemon;
	int socketaffinity;
	int workeraffinity;
	int timeraffinity;
	const char *selfname;
	//please forgive my shortsighted, i think listen max to 16 ports is very many
	char bootstrap[128];
	char lualib_path[256];
	char lualib_cpath[256];
	char logpath[256];
	char pidfile[256];
};


enum x_message_type {
	X_TEXPIRE		= 1,
	X_SACCEPT		= 2,	//new connetiong
	X_SCLOSE,			//close from client
	X_SCONNECTED,		//async connect result
	X_SDATA,			//data packet(raw) from client
	X_SUDP,			//data packet(raw) from client(udp)
};

struct x_message {
	COMMONFIELD
};

struct x_message_texpire {	//timer expire
	COMMONFIELD
	uint32_t session;
};

struct x_message_socket {	//socket accept
	COMMONFIELD
	int sid;
	//SACCEPT, it used as portid,
	//SCLOSE used as errorcode
	//SDATA/SUDP  used by length
	int ud;
	uint8_t *data;
};

static inline void
x_message_free(struct x_message *msg)
{
	int type = msg->type;
	if (type == X_SDATA || type == X_SUDP)
		x_free(tosocket(msg)->data);
	x_free(msg);
}

#endif

