import 'package:mysql1/mysql1.dart';

class Mysql {
  static String host = host,
      user = user,
      password = password,
      db = db;

  static int port = port;

  Mysql();

  Future<MySqlConnection> getConnection() async {
    var settings = ConnectionSettings(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
    );
    return await MySqlConnection.connect(settings);
  }
}
