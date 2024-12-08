import 'package:filetagger/DataStructures/directory_reader.dart';
import 'package:filetagger/Widgets/list_element_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ListWidget extends StatefulWidget {
  const ListWidget({super.key});

  @override
  State<StatefulWidget> createState() => ListWidgetState();
}

class ListWidgetState extends State<ListWidget> {
  bool isSingleSelect = true;
  Set<int> selectedIndices = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget getEmptyWidget(BuildContext context) => Center(
        child: Text(AppLocalizations.of(context)!.emptyContent),
      );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: DirectoryReader().fileList,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
              child: Text(
                  '${AppLocalizations.of(context)!.errorOccur}: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return ListElementWidget(
                file: snapshot.data![index],
                onTap: () {
                  setState(() {
                    if (isSingleSelect) {
                      selectedIndices.clear();
                      selectedIndices.add(index);
                      return;
                    }
                    if (selectedIndices.contains(index)) {
                      selectedIndices.remove(index);
                    } else {
                      selectedIndices.add(index);
                    }
                  });
                },
                isSelected: selectedIndices.contains(index),
              );
            },
          );
        } else {
          return getEmptyWidget(context);
        }
      },
    );
  }
}
