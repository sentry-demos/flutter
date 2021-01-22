//
// Created by Dustin Bailey on 1/19/21.
//
#include <jni.h>
#include <stdint.h>
#include <android/log.h>
#define TAG "sentry-sample"

extern "C" {

JNIEXPORT void JNICALL Java_com_example_sentry_1flutter_1app_MainActivity_crash(JNIEnv *env,jclass cls,jint i){
//__android_log_print(ANDROID_LOG_WARN, TAG, "About to crash with a SEGFAULT in C++!");
    char *ptr = 0;
    *ptr += 1;
}
}