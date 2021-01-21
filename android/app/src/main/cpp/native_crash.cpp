//
// Created by Dustin Bailey on 1/19/21.
//

#include <stdint.h>
#define TAG "sentry-nativesample"

extern "C" {

JNIEXPORT void JNICALL int32_t native_crash(JNIEnv *env, jclass cls) {
    char *ptr = 0;
        *ptr += 1;
}