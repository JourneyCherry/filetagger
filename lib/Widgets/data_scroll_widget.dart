import 'package:filetagger/DataStructures/object.dart';
import 'package:flutter/material.dart';

abstract class DataScrollWidget extends ScrollView {
  const DataScrollWidget({super.key});

  Widget scrollBuild(BuildContext context, List<TrackedObject> objects);
}
