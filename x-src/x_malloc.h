#ifndef _X_MALLOC_H
#define _X_MALLOC_H

#include <stdlib.h>

void *x_malloc(size_t sz);
void *x_realloc(void *ptr, size_t sz);
void x_free(void *ptr);

const char *x_allocator();
size_t x_memused();
size_t x_memrss();

#endif

