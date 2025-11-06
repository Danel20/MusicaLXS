import 'package:flutter/material.dart';

class MusicaLXSApp_Home extends StatefulWidget {
  State<MusicaLXSApp_Home> createState() => _MusicaLXSApp_Home();
}

class _MusicaLXSApp_Home extends State<MusicaLXSApp_Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
          title: Text("MusicaL XS App", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))
      ),
      body: GridView.count(
                  scrollDirection: Axis.vertical,
                  padding: EdgeInsets.all(50),
                  crossAxisSpacing: 50,
                  mainAxisSpacing: 50,
                  crossAxisCount: 2,
                  children: List.generate(100, (index) {
                    return Container(color: Theme.of(context).colorScheme.secondaryFixed, child: Center(
                      child: Text(
                        'Item $index',
                        style: TextTheme.of(context).headlineSmall,
                        ),
                      ));
                  }),
                ),
    );
  }
}