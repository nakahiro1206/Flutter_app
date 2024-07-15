import 'dart:ffi'; // For FFI
import 'dart:io'; // For Platform.isX
import 'package:flutter/material.dart';
   
// ネイティブライブラリをロードするためのDynamicLibraryオブジェクトを作成
final DynamicLibrary nativeAddLib = Platform.isAndroid
      ? DynamicLibrary.open('libprimitives.so')
      : DynamicLibrary.process();
   
// DynamicLibraryオブジェクトから検索された関数をDartの関数型に変換
final int Function(int x, int y) nativeAdd = nativeAddLib
      .lookup<NativeFunction<Int32 Function(Int32, Int32)>>('sum')
      .asFunction();

void testNativeAdd() {
  debugPrint("1 + 3 = ${nativeAdd(1, 3)}");
}