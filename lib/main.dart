// ignore_for_file: prefer_const_constructors, avoid_print, prefer_const_literals_to_create_immutables

import 'package:flutter/material.dart';
import 'package:icons_flutter/icons_flutter.dart';
import 'package:noted/logic/models/mysql.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math';

Future<void> main() async {
  var appState = MyAppState();
  await appState.fetchDataFromDB(); // Fetch data before running the app
  runApp(MyApp(appState: appState));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key, required this.appState}) : super(key: key);
  final MyAppState appState;

  @override
  Widget build(BuildContext context) {
    var fontfamily = GoogleFonts.getFont('Atomic Age');
    return ChangeNotifierProvider.value(
        value: appState,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Noted!',
            theme: ThemeData(
              useMaterial3: true,
              colorScheme:
                  ColorScheme.fromSeed(seedColor: Colors.lightGreenAccent),
              textTheme: TextTheme(
                bodyLarge: fontfamily,
                bodyMedium: fontfamily,
                bodySmall: fontfamily,
              ),
            ),
            home: DefaultTabController(
              length: 3,
              child: Scaffold(
                appBar: AppBar(
                  centerTitle: true,
                  bottom: TabBar(
                      indicatorColor: Colors.lightGreenAccent,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabs: const [
                        Tab(icon: Icon(Icons.home)),
                        Tab(icon: Icon(Icons.access_alarm_sharp)),
                        Tab(icon: Icon(Icons.archive_outlined)),
                      ]),
                  title: Text(
                    "Task View",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Atomic Age',
                    ),
                  ),
                ),
                body: TabBarView(
                  children: [ToDoPage(), Reminders(), Archive()],
                ),
              ),
            )));
  }
}

class MyAppState extends ChangeNotifier {
  var db = new Mysql();
  var rng = Random();

  late String current;
  late bool isDone;

  Map<String, DateTime> completionTimes = {};
  Map<String, DateTime?> reminders = {};

  List<String> tasks = [];
  List<String> archivedTasks = [];
  List<DateTime> reminderTimes = [];
  List<String> reminderTasks = [];

  DateTime? _selectedDateTime;
  DateTime? get selectedDateTime => _selectedDateTime;

  set selectedDateTime(DateTime? dateTime) {
    _selectedDateTime = dateTime;
    notifyListeners();
  }

  void setReminderForTask(String task, DateTime? dateTime) {
    reminders[task] = dateTime;
    notifyListeners();
  }

  Future<DateTime?> showDateTimePicker(BuildContext context) async {
    return await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2099),
    ).then((selectedDate) {
      if (selectedDate != null) {
        return showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        ).then((selectedTime) {
          if (selectedTime != null) {
            return DateTime(
              selectedDate.year,
              selectedDate.month,
              selectedDate.day,
              selectedTime.hour,
              selectedTime.minute,
            );
          }
          return null;
        });
      }
      return null;
    });
  }

  Future<void> fetchDataFromDB() async {
    try {
      var conn = await db.getConnection();
      String sql = "SELECT * FROM tasklist";
      String sql2 = "SELECT * FROM archivedtasklist";
      String sql3 = "SELECT * FROM reminderlist";
      tasks.clear();
      await conn.query(sql).then((results) {
        for (var row in results) {
          tasks.add(row['task_name']);
        }
        print("Data successfully fetched from database - tasklist.");
        print(tasks);
      });
      await conn.query(sql2).then((results) {
        for (var row in results) {
          archivedTasks.add(row['arctask_name']);
        }
        print("Data successfully fetched from database - archivedtasklist.");
        print(archivedTasks);
      });
      await conn.query(sql3).then((results) {
        for (var row in results) {
          reminderTasks.add(row['task_name']);
        }
        print("Data successfully fetched from database - reminderlist.");
        print(reminderTasks);
      });
      notifyListeners();
      conn.close();
    } catch (e) {
      print("Error fetching data from database: $e");
    }
  }

  void addNewTask(String current) async {
    try {
      var conn = await db.getConnection();
      String sql =
          "INSERT INTO tasklist VALUES (${rng.nextInt(100) + 1}, '$current', FALSE);";
      await conn.query(sql).then((results) {
        print("Task $current successfully added to database.");
      });
      tasks.add(current);
      notifyListeners();
      conn.close();
    } catch (e) {
      print("add task: Error adding task: $e");
    }
  }

  void addNewReminder(String task) async {
  try {
    var conn = await db.getConnection();
    String sql =
        "INSERT INTO reminderlist (task_id, task_name, reminder_time) VALUES (?, ?, ?)";
    
    var reminderId = rng.nextInt(100) + 1;
    
    await conn.query(sql, [reminderId, task, selectedDateTime.toString()]);
    print("Successfully set a reminder for task $task.");
    
    reminderTasks.add(task);
    notifyListeners();
    conn.close();
  } catch (e) {
    print("add reminder: Error adding task: $e");
  }
}


  void deleteTask(String task) async {
    try {
      var conn = await db.getConnection();
      String sql =
          "DELETE FROM tasklist WHERE task_name = '$task' COLLATE utf8mb4_general_ci";
      await conn.query(sql).then((results) {
        print("Task $task successfully deleted from database.");
      });
      tasks.remove(task);
      notifyListeners();
      conn.close();
    } catch (e) {
      print("delete task: Error adding task: $e");
    }
  }

  void addArchivedTask(String task) async {
    try {
      var conn = await db.getConnection();
      String sql =
          "UPDATE tasklist SET task_ISDONE = TRUE WHERE task_name = '$task'";
      String sql2 =
          "INSERT INTO archivedtasklist (arctask_id, arctask_name, arctask_timeComp) VALUES (?, ?, ?)";
      await conn.query(sql).then((results) {
        print("Task $task successfully marked as done.");
      });
      await conn.query(sql2,
          [rng.nextInt(100) + 1, task, DateTime.now().toUtc()]).then((results) {
        for (var row in results) {
          completionTimes[task] = DateTime.now().toUtc();
        }
        print("Task $task successfully archived.");
      });
      tasks.remove(task);
      archivedTasks.add(task);
      notifyListeners();
      conn.close();
    } catch (e) {
      print("mark task as done: Error adding task: $e");
    }
  }

  void clearDB() async {
    try {
      var conn = await db.getConnection();
      String sql = "TRUNCATE TABLE tasklist";
      await conn.query(sql).then((results) {
        print("All tasks cleared from the database.");
      });
      tasks.clear();
      notifyListeners();
      conn.close();
    } catch (e) {
      print("Error deleting tasks: $e");
    }
  }

  void clearArcDB(String task) async {
    try {
      var conn = await db.getConnection();
      String sql =
          "DELETE FROM tasklist WHERE task_name = '$task' COLLATE utf8mb4_general_ci";
      String sql2 =
          "DELETE FROM archivedtasklist WHERE arctask_name = '$task' COLLATE utf8mb4_general_ci";
      await conn.query(sql).then((results) {
        print("Archived task $task cleared from the database tasklist.");
      });
      await conn.query(sql2).then((results) {
        print(
            "Archived task $task cleared from the database archivedtasklist.");
      });
      archivedTasks.remove(task);
      notifyListeners();
      conn.close();
    } catch (e) {
      print("Error deleting tasks: $e");
    }
  }
}

class ToDoPage extends StatelessWidget {
  TextEditingController t = TextEditingController();
  @override
  Widget build(BuildContext context) {
    AlertDialog errTaskEmpty() {
      return AlertDialog(
        title: const Text("Error"),
        content: const Text("Task cannot be empty."),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, 'OK'),
            child: const Text('OK'),
          ),
        ],
      );
    }

    var appState = context.watch<MyAppState>();
    return Scaffold(
        body: SingleChildScrollView(
            child: Center(
                child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Noted!",
          style: const TextStyle(fontSize: 100),
        ),
        SizedBox(
          width: 325,
          child: TextField(
            controller: t,
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Add new task',
              icon: const Icon(Icons.add_task_sharp),
            ),
            maxLines: 2,
            minLines: 1,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                appState.current = t.text;
                if (appState.current.isEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return errTaskEmpty();
                    },
                  );
                } else {
                  appState.addNewTask(appState.current);
                }
              },
              child: const Text("Create Task"),
            ),
            ElevatedButton(
              onPressed: () async {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Confirmation"),
                      content: const Text(
                          "Are you sure you want to clear all tasks?"),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.pop(context, 'No'),
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, 'Yes');
                            appState.clearDB();
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text("Clear All"),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ListView.builder(
          shrinkWrap: true,
          itemCount: appState.tasks.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: 15,
              child: Container(
                margin: const EdgeInsets.all(10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(appState.tasks[index]),
                  SizedBox(width: 70),
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.deleteTask(appState.tasks[index]);
                    },
                    icon: Icon(Octicons.x),
                    label: Text("Delete"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.addArchivedTask(appState.tasks[index]);
                    },
                    icon: Icon(Octicons.check),
                    label: Text("Mark done"),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      showModalBottomSheet(
                          context: context,
                          builder: (BuildContext context) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children: <Widget>[
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.task),
                                            Text("Status: Not done")
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.notifications_active),
                                            Text(
                                              appState.reminders[appState
                                                          .tasks[index]] ==
                                                      null
                                                  ? "Reminder: Not set"
                                                  : "Reminder: ${appState.reminders[appState.tasks[index]]!.toString().substring(0, 16)}",
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(
                                      height: 10,
                                    ),
                                    ElevatedButton(
                                      child: const Text('Set a Reminder'),
                                      onPressed: () {
                                        appState
                                            .showDateTimePicker(context)
                                            .then((selectedDateTime) {
                                          if (selectedDateTime != null) {
                                            appState.setReminderForTask(
                                                appState.tasks[index],
                                                selectedDateTime);
                                            appState.reminderTimes
                                                .add(selectedDateTime);
                                            appState.reminderTasks
                                                .add(appState.tasks[index]);
                                            appState.addNewReminder(
                                                appState.tasks[index]);
                                            Navigator.pop(context);
                                          }
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                    },
                    icon: Icon(Icons.settings),
                    label: Text("Details"),
                  )
                ]),
              ),
            );
          },
        ),
      ],
    ))));
  }
}

class Archive extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.archivedTasks.isEmpty) {
      return Center(child: Text("No archived tasks here!"));
    }

    return ListView(
      children: [
        Center(
            child: Text(
                "You have ${appState.archivedTasks.length} archived tasks:")),
        for (int i = 0; i < appState.archivedTasks.length; i++)
          ListTile(
            leading: Icon(Icons.check_box_rounded),
            title: Text(appState.archivedTasks[i]),
            trailing: IconButton(
              onPressed: () {
                appState.clearArcDB(appState.archivedTasks[i]);
              },
              icon: Icon(Icons.delete_forever_rounded),
            ),
            subtitle: Text(
                "Completed at: ${appState.completionTimes[appState.archivedTasks[i]]}"),
          ),
      ],
    );
  }
}

class Reminders extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    if (appState.reminderTimes.isEmpty) {
      return Center(
          child: Text(
              "No reminders set. Press the Details button to set a reminder!"));
    }

    var tasksWithReminders = appState.tasks.where((task) =>
        appState.reminders.containsKey(task) &&
        appState.reminders[task] != null);

    if (tasksWithReminders.isEmpty) {
      return Center(child: Text("No reminders set. Press the Details button to set a reminder!"));
    }

    return ListView(
      children: [
        Center(child: Text("You have ${tasksWithReminders.length} reminders:")),
        for (var task in tasksWithReminders)
          ListTile(
            leading: Icon(Icons.notifications_active),
            title: Text(task),
            trailing: IconButton(
              onPressed: () {},
              icon: Icon(Icons.notifications_none),
            ),
            subtitle: Text("Reminder set for: ${appState.reminders[task]}"),
          ),
      ],
    );
  }
}
