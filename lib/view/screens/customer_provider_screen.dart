import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomerProviderScreen extends StatefulWidget{
  @override
  State<StatefulWidget> createState() =>_CustomerProviderScreen();
}
class _CustomerProviderScreen extends State<CustomerProviderScreen>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              height: 850,
              width: 360/2,
              color: Color(0xFF0A1F44),
            )
          ],
        ),
      ),
    );

  }

}