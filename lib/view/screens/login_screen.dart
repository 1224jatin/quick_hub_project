import 'package:flutter/material.dart';
import 'package:quick_hub_project/view/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _LoginScreen();


}

class _LoginScreen extends State<LoginScreen> {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
          child: Column(
            children: [
              ClipPath(
                clipper: MyCustomClipper(),
                child: Container(
                  height: 200,
                  color: const Color(0xFF0A1F44),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text("Quick Hub",
                          style: TextStyle(fontSize: 30,fontWeight: FontWeight.bold,color: Colors.white),),
                        Text(
                        ' "Sab Kaam Yahan" ' ,
                        style: TextStyle(color: Colors.white, fontSize: 10, ),
                      ),
                      ]
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsetsGeometry.symmetric(vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(padding: EdgeInsetsGeometry.all(40)),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

                      ],

                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.attach_email_rounded),
                        Container(
                          width: 280,
                          padding: EdgeInsets.all(10),
                          child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Email",
                            ),
                          ),
                        )
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(Icons.password_sharp),
                        Container(
                          width: 280,
                          padding: EdgeInsets.all(10),
                          child: TextField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              labelText: "Password",
                            ),
                          ),
                        )
                      ],
                    ),
                    SizedBox(height: 50),
                    ElevatedButton(onPressed: (){

                    },child: const Text("Log In")),
                    Container(height: 20,margin: EdgeInsetsGeometry.symmetric(vertical: 220),
                      child: InkWell(
                        child:Text("Not have any account?/ Sign up " ),
                        onTap: (){
                          Navigator.push(context, MaterialPageRoute(builder: (context)=>RegisterScreen()));
                        },
                      ),)
                  ],
                ),
              )
            ],
          )),
    );
  }
}

class MyCustomClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 70);
    path.quadraticBezierTo(
        size.width / 2, size.height, size.width, size.height/2 + 25);
    path.lineTo(size.width , 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
