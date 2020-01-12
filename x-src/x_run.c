#include "x_conf.h"
#include <unistd.h>
#include <signal.h>
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>

#include "x.h"
#include "compiler.h"
#include "x_log.h"
#include "x_env.h"
#include "x_malloc.h"
#include "x_timer.h"
#include "x_socket.h"
#include "x_worker.h"
#include "x_daemon.h"

#include "x_run.h"

struct {
	int running;
	int workerstatus; /* 0:sleep 1:running -1:dead */
	const struct x_config *conf;
	pthread_mutex_t mutex;
	pthread_cond_t cond;
} R;// R means run.


static void *
thread_timer(void *arg)
{
	(void)arg;
	for (;;) {
		x_timer_update();
		if (R.workerstatus == -1)
			break;
		usleep(TIMER_ACCURACY);
		if (R.workerstatus == 0)
			pthread_cond_signal(&R.cond);
	}
	x_socket_terminate();
	return NULL;
}


static void *
thread_socket(void *arg)
{
	(void)arg;
	for (;;) {
		int err = x_socket_poll();
		if (err < 0)
			break;
		if (R.workerstatus == 0)
			pthread_cond_signal(&R.cond);
	}
	return NULL;
}

static void *
thread_worker(void *arg)
{
	const struct x_config *c;
	c = (struct x_config *)arg;
	x_worker_start(c);
	pthread_mutex_lock(&R.mutex);
	while (R.running) {
		x_worker_dispatch();
		//allow spurious wakeup, it's harmless
		R.workerstatus = 0;
		pthread_cond_wait(&R.cond, &R.mutex);
		R.workerstatus = 1;
	}
	pthread_mutex_unlock(&R.mutex);
	R.workerstatus = -1;
	return NULL;
}

static void
thread_create(pthread_t *tid, void *(*start)(void *), void *arg, int cpuid)
{
	int err;
	err = pthread_create(tid, NULL, start, arg);
	if (unlikely(err < 0)) {
		x_log("thread create fail:%d\n", err);
		exit(-1);
	}
#ifdef USE_CPU_AFFINITY
	if (cpuid < 0)
		return ;
	cpu_set_t cpuset;
	CPU_ZERO(&cpuset);
	CPU_SET(cpuid, &cpuset);
	pthread_setaffinity_np(*tid, sizeof(cpuset), &cpuset);
#else
	(void)cpuid;
#endif
	return ;
}

static void
signal_term(int sig)
{
	(void)sig;
	R.running = 0;
}

static void
signal_usr1(int sig)
{
	(void)sig;
	x_daemon_sigusr1(R.conf);
}

static int
signal_init()
{
	signal(SIGPIPE, SIG_IGN);
	signal(SIGTERM, signal_term);
	signal(SIGINT, signal_term);
	signal(SIGUSR1, signal_usr1);
	return 0;
}

void
x_run(const struct x_config *config)
{
	int i;
	int err;
	pthread_t pid[3];
	R.running = 1;
	R.conf = config;
	pthread_mutex_init(&R.mutex, NULL);
	pthread_cond_init(&R.cond, NULL);
	x_daemon_start(config);
	x_log_start();
	signal_init();
	// init memory, clocktime, ticktime, expire, monotonic and lock for T
	x_timer_init();
	// in x_socket.c, set SSOCKET mainly
	err = x_socket_init();
	if (unlikely(err < 0)) {
		x_log("%s socket init fail:%d\n", config->selfname, err);
		x_daemon_stop(config);
		exit(-1);
	}
	// init memory, maxmsg and message queue for W
	x_worker_init();
	srand(time(NULL));
	thread_create(&pid[0], thread_socket, NULL, config->socketaffinity);
	thread_create(&pid[1], thread_timer, NULL, config->timeraffinity);
	thread_create(&pid[2], thread_worker, (void *)config, config->workeraffinity);
	x_log("%s %s is running ...\n", config->selfname, X_RELEASE);
	x_log("cpu affinity setting, timer:%d, socket:%d, worker:%d\n",
		config->timeraffinity, config->socketaffinity, config->workeraffinity);
	for (i = 0; i < 3; i++)
		pthread_join(pid[i], NULL);
	x_daemon_stop(config);
	pthread_mutex_destroy(&R.mutex);
	pthread_cond_destroy(&R.cond);
	x_worker_exit();
	x_timer_exit();
	x_socket_exit();
	x_log("%s has already exit...\n", config->selfname);
	return ;
}

void
x_exit()
{
	R.running = 0;
}


