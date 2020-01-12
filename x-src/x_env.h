#ifndef _X_ENV_H
#define _X_ENV_H

int x_env_init();
const char *x_env_get(const char *key);
void x_env_set(const char *key, const char *value);
void x_env_exit();

#endif

