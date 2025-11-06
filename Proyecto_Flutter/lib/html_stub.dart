class NavigatorStub {
  final bool onLine = true;
}

class WindowStub {
  final NavigatorStub navigator = NavigatorStub();
}

final WindowStub window = WindowStub();