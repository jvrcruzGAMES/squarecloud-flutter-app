import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:squarecloud_app/frameworks/session.dart';
import 'package:squarecloud_app/frameworks/upload.dart';
import 'package:squarecloud_app/frameworks/varstore.dart';
import 'package:squarecloud_app/frameworks/dynamic.dart';



void main() {
  runApp(const SquareCloudApp());
}

class SquareCloudApp extends StatelessWidget {
  const SquareCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Square Cloud',
      home: SquareCloudLoginPage(),
    );  
  }
}

AppBar appBar = AppBar(
  title: const Text('Square Cloud', style: TextStyle(color: Colors.white)),
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  actions: const [],
);

class SquareCloudLoginPage extends StatelessWidget {
  SquareCloudLoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Session();
    session.init().then((_) async {
      bool loggedIn = await session.isValid();
      if (loggedIn) {
        Fluttertoast.showToast(msg: "Logged in");
        SameProcessStorage.write("session", session);
        SquareLoadingPage loadPage = SquareLoadingPage(loadFunc: (loadContext) async {
          await Future.delayed(const Duration(seconds: 2));
          var page = SquareCloudHomePage(session, Apps(session));
          await Future.doWhile(() async {
            if (page.appList.apps.apps.isEmpty == true) {
              await Future.delayed(const Duration(milliseconds: 300));
              return true;
            } else {
              return false;
            }
          });
          Navigator.pushReplacement(loadContext, MaterialPageRoute(builder: (context) => page));
        });

        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => loadPage));
      } else {
        Fluttertoast.showToast(msg: "Please login");
        SameProcessStorage.delete("session");
      }
    });

    return Scaffold(
      appBar: appBar,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Login to Square Cloud'),
            TextField(
              decoration: const InputDecoration(
                hintText: 'API key',
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (value) async {
                Session session = Session(authToken: value);
                bool valid = await session.isValid();

                SquareLoadingPage loadPage = SquareLoadingPage(loadFunc: (loadContext) async {
                  await Future.delayed(const Duration(seconds: 2));
                  var page = SquareCloudHomePage(session, Apps(session));
                  await Future.doWhile(() async {
                    if (page.appList.apps.apps.isEmpty == true) {
                      await Future.delayed(const Duration(milliseconds: 300));
                      return true;
                    } else {
                      return false;
                    }
                  });
                  Navigator.pushReplacement(loadContext, MaterialPageRoute(builder: (context) => page));
                });

                if (valid) {
                  Fluttertoast.showToast(msg: "Logged in");
                  SameProcessStorage.write("session", session);
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => loadPage));
                } else {
                  Fluttertoast.showToast(msg: "Invalid API key");
                }
                
              },
            )
          ],
        ),
      ),
    );
  }
}


AppBar squareHomeAppBar = AppBar(
  title: const Text('Square Cloud', style: TextStyle(color: Colors.white)),
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
  actions: [
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () {
        UploadManager.selectFile().then((path) {
          if (path != null) {
            UploadManager.uploadApp(path).then((code) {
              Fluttertoast.showToast(msg: "Attempt result: $code");
            });
          }
        });
      },
    )
  ],
);


class SquareCloudHomePage extends StatelessWidget {
  late final Session session;
  late final Apps apps;
  late final SquareAppList appList;
  SquareCloudHomePage(Session session, Apps apps, {super.key}) {
    this.apps = apps;
    this.session = session;
    this.appList = SquareAppList(session, apps);
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: squareHomeAppBar,
      body: Center(
        child: appList,
      ),
    );
  }
}