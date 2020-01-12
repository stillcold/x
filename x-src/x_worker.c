#include <assert.h>
#include <stdio.h>
#include <string.h>
#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>

#include "x.h"
#include "compiler.h"
#include "x_log.h"
#include "x_malloc.h"
#include "x_queue.h"
#include "x_worker.h"

#define max(a, b)	((a) > (b) ? (a) : (b))


struct x_worker {
	lua_State *L;
	uint32_t id;
	size_t maxmsg;
	struct x_queue *queue;
	void (*callback)(lua_State *L, struct x_message *msg);
};

struct x_worker *W;

// Sockect thread will call this method and keep push data to message queue. 
void
x_worker_push(struct x_message *msg)
{
	size_t sz;
	sz = x_queue_push(W->queue, msg);
	if (unlikely(sz > W->maxmsg)) {
		W->maxmsg *= 2;
		x_log("may overload, now message size is:%zu\n", sz);
	}
}

// Worker thread will handle all message pushed by socket thread.
void
x_worker_dispatch()
{
	struct x_message *msg;
	struct x_message *tmp;
	msg = x_queue_pop(W->queue);
	while (msg) {
		assert(W->callback);
		// Here is the logic entrance.
		W->callback(W->L, msg);
		tmp = msg;
		msg = msg->next;
		x_message_free(tmp);
	}
	return ;
}

uint32_t
x_worker_genid()
{
	return W->id++;
}

size_t
x_worker_msgsize()
{
	return x_queue_size(W->queue);
}

void
x_worker_callback(void (*callback)(struct lua_State *L, struct x_message *msg))
{
	assert(callback);
	W->callback = callback;
	return ;
}

static int
setlibpath(lua_State *L, const char *libpath, const char *clibpath)
{
	const char *path;
	const char *cpath;
	size_t sz1 = strlen(libpath);
	size_t sz2 = strlen(clibpath);
	size_t sz3;
	size_t sz4;
	size_t need_sz;

	lua_getglobal(L, "package");
	lua_getfield(L, -1, "path");
	path = luaL_checklstring(L, -1, &sz3);

	lua_getfield(L, -2, "cpath");
	cpath = luaL_checklstring(L, -1, &sz4);

	need_sz = max(sz1, sz2) + max(sz3, sz4) + 1;
	char new_path[need_sz];

	snprintf(new_path, need_sz, "%s;%s", libpath, path);
	lua_pushstring(L, new_path);
	lua_setfield(L, -4, "path");

	snprintf(new_path, need_sz, "%s;%s", clibpath, cpath);
	lua_pushstring(L, new_path);
	lua_setfield(L, -4, "cpath");

	//clear the stack
	lua_settop(L, 0);
	return 0;
}

static void *
lua_alloc(void *ud, void *ptr, size_t osize, size_t nsize)
{
	(void) ud;
	(void) osize;
	if (nsize == 0) {
		x_free(ptr);
		return NULL;
	} else {
		return x_realloc(ptr, nsize);
	}
}

void
x_worker_start(const struct x_config *config)
{
	int err;
	lua_State *L = lua_newstate(lua_alloc, NULL);
	luaL_openlibs(L);
	err = setlibpath(L, config->lualib_path, config->lualib_cpath);
	if (unlikely(err != 0)) {
		x_log("x worker set lua libpath fail,%s\n",
			lua_tostring(L, -1));
		lua_close(L);
		exit(-1);
	}
	lua_gc(L, LUA_GCRESTART, 0);
	err = luaL_loadfile(L, config->bootstrap);
	if (unlikely(err) || unlikely(lua_pcall(L, 0, 0, 0))) {
		x_log("x worker call %s fail,%s\n",
			config->bootstrap, lua_tostring(L, -1));
		lua_close(L);
		exit(-1);
	}
	W->L = L;
	return ;
}

void
x_worker_init()
{
	W = (struct x_worker *)x_malloc(sizeof(*W));
	memset(W, 0, sizeof(*W));
	W->maxmsg = 128;
	W->queue = x_queue_create();
	return ;
}

void
x_worker_exit()
{
	lua_close(W->L);
	x_queue_free(W->queue);
	x_free(W);
}

