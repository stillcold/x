#include <stdio.h>
#include "atomic.h"
#include "spinlock.h"
#include "x.h"
#include "x_malloc.h"

#include "x_queue.h"

struct x_queue {
	size_t size;
	struct x_message **tail;
	struct x_message *head;
	spinlock_t lock;
};

static inline void
lock(struct x_queue *q)
{
	spinlock_lock(&q->lock);
}

static inline void
unlock(struct x_queue *q)
{
	spinlock_unlock(&q->lock);
	return ;
}

struct x_queue *
x_queue_create()
{
	struct x_queue *q = (struct x_queue *)x_malloc(sizeof(*q));
	q->size = 0;
	q->head = NULL;
	q->tail = &q->head;
	spinlock_init(&q->lock);
	return q;
}

void
x_queue_free(struct x_queue *q)
{
	struct x_message *next, *tmp;
	lock(q);
	next = q->head;
	while (next) {
		tmp = next;
		next = next->next;
		x_message_free(tmp);
	}
	unlock(q);
	spinlock_destroy(&q->lock);
	x_free(q);
	return ;
}

int
x_queue_push(struct x_queue *q, struct x_message *msg)
{
	msg->next = NULL;
	lock(q);
	*q->tail = msg;
	q->tail = &msg->next;
	unlock(q);
	return atomic_add_return(&q->size, 1);
}


struct x_message *
x_queue_pop(struct x_queue *q)
{
	struct x_message *msg;
	if (q->head == NULL)
		return NULL;
	lock(q);
	//double check
	if (q->head == NULL) {
		unlock(q);
		return NULL;
	}
	msg = q->head;
	q->head = NULL;
	q->tail = &q->head;
	unlock(q);
	atomic_xor(&q->size, q->size);
	return msg;
}

size_t
x_queue_size(struct x_queue *q)
{
	return q->size;
}

