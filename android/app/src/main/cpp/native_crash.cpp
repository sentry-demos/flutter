//
// Created by Dustin Bailey on 1/19/21.
//

#include <stdint.h>

extern "C" __attribute__((visibility("default"))) __attribute__((used))
int32_t native_crash(int32_t x, int32_t y) {
    char *ptr = 0;
        *ptr += 1;
}