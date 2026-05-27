import 'package:flutter/material.dart';

class AutocompleteField
    extends StatelessWidget {

  final TextEditingController controller;

  final List<String> source;

  final String label;

  const AutocompleteField({
    super.key,
    required this.controller,
    required this.source,
    required this.label,
  });

  @override
  Widget build(
      BuildContext context,
      ) {

    return Autocomplete<String>(

      optionsBuilder:
          (value) {

        return SearchService
            .autocomplete(
          value.text,
          source,
        );
      },

      onSelected:
          (value) {

        controller.text =
            value;
      },

      fieldViewBuilder:
          (
          context,
          controllerAuto,
          focusNode,
          onSubmit,
          ) {

        controllerAuto.text =
            controller.text;

        return TextField(
          controller:
          controllerAuto,
          focusNode:
          focusNode,
          decoration:
          InputDecoration(
            labelText:
            label,
          ),
        );
      },
    );
  }
}