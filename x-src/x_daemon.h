#ifndef _X_DAEMON_H
#define _X_DAEMON_H

void x_daemon_start(const struct x_config *conf);
void x_daemon_sigusr1(const struct x_config *conf);
void x_daemon_stop(const struct x_config *conf);


#endif

