import 'dart:async';

mixin ContainerEventHandlerMixin<AddType, DelType> {
  final _addEventController = StreamController<AddType>();
  final _delEventController = StreamController<DelType>();

  Stream<AddType> get addEvent => _addEventController.stream;
  Stream<DelType> get delEvent => _delEventController.stream;

  void invokeAdd(AddType data) => _addEventController.add(data);
  void invokeDel(DelType data) => _delEventController.add(data);
}
