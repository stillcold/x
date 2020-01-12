#ifndef _X_WORKER_H
#define _X_WORKER_H

struct x_message;
struct lua_State;

void x_worker_init();
void x_worker_exit();

void x_worker_start(const struct x_config *config);

void x_worker_push(struct x_message *msg);
void x_worker_dispatch();

uint32_t x_worker_genid();
size_t x_worker_msgsize();

void x_worker_callback(void (*callback)(struct lua_State *L, struct x_message *msg));

#endif

