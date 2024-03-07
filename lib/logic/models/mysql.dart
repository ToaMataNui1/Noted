import 'package:mysql1/mysql1.dart';

class Mysql {
  static String host =
          "sqlclassdb-instance-1.cqjxl5z5vyvr.us-east-2.rds.amazonaws.com",
      user = "srivem25",
      password = "sHhAU9dGgrGd",
      db = "inventory_webapps_2324t2_TF_srivem25";

  static int port = 3306;

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
