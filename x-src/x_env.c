#include <lua.h>
#include <lauxlib.h>

#include "x_malloc.h"

#include "x_env.h"

struct x_env {
	lua_State *L;
};

static struct x_env *E;

const char *x_env_get(const char *key)
{
	const char *value;
	lua_State *L = E->L;
	lua_getglobal(L, key);
	value = lua_tostring(L, -1);
	lua_pop(L, 1);
	return value;
}

void x_env_set(const char *key, const char *value)
{
	lua_State *L = E->L;
	lua_pushstring(L, value);
	lua_setglobal(L, key);
	return ;
}


int
x_env_init()
{
	E = (struct x_env *)x_malloc(sizeof(*E));
	E->L = luaL_newstate();
	return 0;
}

void
x_env_exit()
{
	lua_close(E->L);
	x_free(E);
	return ;
}

