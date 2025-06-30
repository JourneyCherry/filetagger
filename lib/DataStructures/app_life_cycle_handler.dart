import 'package:flutter/material.dart';

class AppLifecycleHandler with WidgetsBindingObserver {
  final VoidCallback onAppPause;

  AppLifecycleHandler(this.onAppPause);

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      onAppPause(); // Android/iOS 백그라운드 진입 시점
    }
    if (state == AppLifecycleState.detached) {
      onAppPause(); // 데스크탑 종료 감지 시도
    }
  }
}
