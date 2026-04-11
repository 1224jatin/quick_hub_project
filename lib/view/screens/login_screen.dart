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
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A1F44),
        leading: const Icon(
          Icons.quick_contacts_mail,
          color: Colors.white,
        ),
        title: const Text(
          "Welcome To QuickHub",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
          child: Column(
            children: [
              ClipPath(
                clipper: MyCustomClipper(),
                child: Container(
                  height: 200,
                  color: const Color(0xFF0A1F44),
                  child: const Center(
                    child: Text(
                      "Fast, reliable, and trusted — your daily needs, simplified.",
                      style: TextStyle(color: Colors.white, fontSize: 12, ),
                    ),
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  InkWell(
                    child: Container(padding: EdgeInsets.fromLTRB(0, 210, 0, 0),
                      child: Text("Not have any account?/ Sign up " ),
                    ),onTap: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context)=>RegisterScreen()));
                  },
                  )
                ],
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
