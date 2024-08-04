import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_console_widget/flutter_console.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:squarecloud_app/frameworks/session.dart';
import 'package:squarecloud_app/frameworks/squareapi.dart';
import 'package:squarecloud_app/frameworks/upload.dart';
import 'package:squarecloud_app/frameworks/varstore.dart';


AppBar appBar = AppBar(
  title: const Text('Square Cloud', style: TextStyle(color: Colors.white)),
  backgroundColor: Colors.black,
  foregroundColor: Colors.white,
);

class AppStatus with ChangeNotifier {
  var online = false;
  late final String appID;
  late final Session session;

  AppStatus(String id, Session session) {
    appID = id;
    this.session = session;
    updateStatus();
  }

  void updateStatus() async {
    final response = await session.getAPI().get("/v2/apps/$appID/status");
    if (response["status"] == "success") {
      online = response["response"]["running"];
      notifyListeners();
    } else {
      online = false;
      notifyListeners();
    }
    await Future.delayed(const Duration(seconds: 20));
    updateStatus();
  }
}

class App {
  final String name;
  final String? custom;
  final String domain;
  final String? desc;
  final String id;
  final Session session;
  late final AppStatus status;

  App(this.name, this.domain, this.custom, this.desc, this.id, this.session) {
    this.status = AppStatus(id, session);
  }
}

class SquareAppInfoPage extends StatefulWidget {
  late final App app;
  SquareAppInfoPage({super.key, required Map<String, dynamic> app}) {
    this.app = App(app["name"], app["domain"], app["custom"], app["desc"], app["id"], SameProcessStorage.read("session"));
  }
  


  @override
  State<SquareAppInfoPage> createState() {
    return _SquareAppInfoPageState();
  }
}

class _SquareAppInfoPageState extends State<SquareAppInfoPage> {
  @override
  Widget build(BuildContext context) {
    widget.app.status.addListener(() async {
      await Future.delayed(const Duration(seconds: 2));
      setState(() {});
    });

    App app = widget.app;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Square Cloud', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.upload),
            onPressed: () async {
              UploadManager.selectFile().then((path) {
                if (path != null) {
                  UploadManager.commitApp(path, app.id).then((code) {
                    Fluttertoast.showToast(msg: "Attempt result: $code");
                  });
                }
              });
            },
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(app.name),
            Text(app.custom ?? app.domain),
            Text(app.desc ?? "No description"),
            Text("Status: ${app.status.online ? "Online" : "Offline"}"),
            DefaultTabController(length: 2, child: SizedBox(
              width: MediaQuery.of(context).size.width,
              height: 400,
              child: Scaffold(
              resizeToAvoidBottomInset: true,
              appBar: const TabBar(
                tabs: [
                  Tab(text: "Settings"),
                  Tab(text: "Console"),
                ],
              ),
              body: TabBarView(
                children: [
                  SettingsWidget(app.id),
                  ConsoleWidget(app.id),
                ],
              ),
            ),
            ))
          ],
        ),
      ),
    );
  }
}

class SettingsWidget extends StatelessWidget {
  late final String appID;
  SettingsWidget(String id, {super.key}) {
    appID = id;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListView(
        children: [
          ListTile(
            title: const Text("Delete app"),
            subtitle: const Text("Delete this app"),
            trailing: const Icon(Icons.delete),
            tileColor: Colors.red,
            iconColor: Colors.white,
            textColor: Colors.white,
            onTap: () {
              showDialog(context: context, builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text("Delete app"),
                  content: const Text("Are you sure you want to delete this app?"),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        Session session = SameProcessStorage.read("session");
                        SquareAPI api = session.getAPI();
                        api.delete("/v2/apps/$appID").then((response) {
                        if (response["status"] == "success") {
                            Navigator.of(context).pop();
                            Navigator.of(context).pop();
                        } else {
                            Navigator.of(context).pop();
                            showDialog(context: context, builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Failed to delete app"),
                                content: const Text("Failed to delete app"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("OK"),
                                  )
                                ],
                              );
                            });
                          }
                        });
                      },
                      child: const Text("Delete"),
                    )
                  ],
                );
              });
            },  
          )
        ],
      )
    );
  }
}

class ConsoleWidget extends StatelessWidget {
  late final String appID;
  ConsoleWidget(String id, {super.key}) {
    appID = id;
  }

  final FlutterConsoleController controller = FlutterConsoleController();
  final double height = 350;
  late final double width;

  void updateConsole(String appId) async {
    controller.clear();
    controller.print(message: "[SQUARE] Type help for commands", endline: true);
    controller.print(message:  "[SQUARE] Loading console for $appId", endline: true);
    Session session = SameProcessStorage.read("session");
    SquareAPI api = session.getAPI();
    final response = await api.get("/v2/apps/$appId/logs");
    if (response["status"] == "success") {
      var logs = response["response"]["logs"];
      for (var log in logs.split("\n")) {
        controller.print(message: log, endline: true);
      }
    } else {
      controller.print(message: "[SQUARE] Failed to load logs, updating in 30 seconds", endline: true);
      print(response);
    }
    await Future.delayed(const Duration(seconds: 30));
    updateConsole(appId);
  }

  void commandListener(String appId) {
    controller.scan().then((command) async {
      Session session = SameProcessStorage.read("session");
      SquareAPI api = session.getAPI();
      if (command == "start") {
        controller.print(message: "[SQUARE] Starting app $appId", endline: true);
        final response = await api.post("/v2/apps/$appId/start", null);
        if (response["status"] == "success") {
          controller.print(message: "[SQUARE] App started", endline: true);
        } else {
          controller.print(message: "[SQUARE] Failed to start app", endline: true);
        }
      } else if (command == "stop") {
        controller.print(message: "[SQUARE] Stopping app $appId", endline: true);
        final response = await api.post("/v2/apps/$appId/stop", null);
        if (response["status"] == "success") {
          controller.print(message: "[SQUARE] App stopped", endline: true);
        } else {
          controller.print(message: "[SQUARE] Failed to stop app", endline: true);
        }
      } else if (command == "restart") {
        controller.print(message: "[SQUARE] Restarting app $appId", endline: true);
        final response = await api.post("/v2/apps/$appId/restart", null);
        if (response["status"] == "success") {
          controller.print(message: "[SQUARE] App restarted", endline: true);
        } else {
          controller.print(message: "[SQUARE] Failed to restart app", endline: true);
        }
      } else if (command == "help") {
        controller.print(message: "[SQUARE] Commands: start, stop, restart, help", endline: true);
      } else {
        controller.print(message: "[SQUARE] Unknown command", endline: true);
      }
      commandListener(appId);
    });
  }

  @override
  Widget build(BuildContext context) {
    width =  MediaQuery.of(context).size.width;
    updateConsole(appID);
    commandListener(appID);
    return FlutterConsole(controller: controller, height: height, width: width);
  }
}

class SquareLoadingPage extends StatelessWidget {
  final void Function(BuildContext context) loadFunc;

  const SquareLoadingPage({super.key, required this.loadFunc});

  @override
  Widget build(BuildContext context) {
    loadFunc(context);
    
    return Scaffold(
      appBar: appBar,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}

class Apps with ChangeNotifier {
  List<dynamic> apps = [];
  Session session;

  void updateApps (Session session) async {
    await Future.delayed(const Duration(seconds: 20));
    var response = await session.getAPI().get("/v2/users/me");
    if (response["status"] == "success") {
      apps = response["response"]["applications"];
      notifyListeners();
    } else {
      print(response);
    }
    updateApps(session);
  }
     
  Apps(this.session) {
    session.getAPI().get("/v2/users/me").then((response) {
      if (response["status"] == "success") {
        apps = response["response"]["applications"];
        notifyListeners();
      } else {
        print(response);
      }
    });
    updateApps(session);
  }
}

class SquareAppList extends StatefulWidget {
  late final Session session;
  late final Apps apps;

  SquareAppList(Session session, Apps apps, {super.key}) {
    this.apps = apps;
    this.session = session;
  }

  @override
  State<SquareAppList> createState() {
    return _SquareAppListState();
  }

}

class _SquareAppListState extends State<SquareAppList> {
  @override
  Widget build(BuildContext context) {
    widget.apps.addListener(() async {
      await Future.delayed(const Duration(seconds: 5));
      setState(() {});
    });

    return ListView.builder(
      itemCount: widget.apps.apps.length,
      itemBuilder: (context, index) {
        var app = widget.apps.apps[index];
        return ListTile(
          title: Text(app["name"]),
          subtitle: Text(app["custom"] ?? app["domain"]),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => SquareAppInfoPage(app: app)));
          },
        );
      },
    );
  }
}