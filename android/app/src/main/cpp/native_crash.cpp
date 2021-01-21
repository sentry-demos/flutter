//
// Created by Dustin Bailey on 1/19/21.
//
#include <jni.h>
#include <stdint.h>


extern "C" {

JNIEXPORT void JNICALL native_crash(JNIEnv *env,jclass cls){
    char *ptr = 0;
        *ptr += 1;
}
}