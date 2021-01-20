import 'dart:ffi'; // For FFI
import 'dart:io'; // For Platform.isX

final DynamicLibrary nativeAddLib = Platform.isAndroid
    ? DynamicLibrary.open("libnative_error.so")
    : DynamicLibrary.process();

final int Function(int x, int y) nativeCrash = nativeAddLib
    .lookup<NativeFunction<Int32 Function(Int32, Int32)>>("native_crash")
    .asFunction();
