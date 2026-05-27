class AuthorsWidget
    extends StatefulWidget {

  final List<TextEditingController>
  controllers;

  const AuthorsWidget({
    super.key,
    required this.controllers,
  });

  @override
  State<AuthorsWidget>
  createState()
  =>
      _AuthorsWidgetState();
}

class _AuthorsWidgetState
    extends State<AuthorsWidget> {

  @override
  Widget build(
      BuildContext context,
      ) {

    return Column(

      children: [

        ...widget.controllers
            .asMap()
            .entries
            .map(
              (entry) {

            final index =
                entry.key;

            final controller =
                entry.value;

            return Row(

              children: [

                Expanded(
                  child:
                  TextField(
                    controller:
                    controller,
                    decoration:
                    const InputDecoration(
                      labelText:
                      'Nombre y Apellidos',
                    ),
                  ),
                ),

                IconButton(
                  icon:
                  const Icon(
                    Icons.delete,
                  ),
                  onPressed: () {

                    setState(() {

                      widget.controllers
                          .removeAt(
                        index,
                      );
                    });
                  },
                ),
              ],
            );
          },
        ),

        ElevatedButton.icon(
          onPressed: () {

            setState(() {

              widget.controllers
                  .add(
                TextEditingController(),
              );
            });
          },
          icon:
          const Icon(Icons.add),
          label:
          const Text(
            'Agregar Autor',
          ),
        ),
      ],
    );
  }
}