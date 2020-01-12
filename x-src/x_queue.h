#ifndef _X_QUEUE_H
#define _X_QUEUE_H

struct x_message;
struct x_queue;

struct x_queue *x_queue_create();
void x_queue_free(struct x_queue *q);

//when return from x_push, should not be free the msg
int x_queue_push(struct x_queue *q, struct x_message *msg);

//after use the message returned by x_pop, free it
struct x_message *x_queue_pop(struct x_queue *q);

size_t x_queue_size(struct x_queue *q);

#endif


