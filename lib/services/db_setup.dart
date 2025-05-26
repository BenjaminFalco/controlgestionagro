import 'package:sqflite/sqflite.dart';

Future<void> crearTablas(Database db) async {
  await db.execute("PRAGMA foreign_keys = ON;");

  await db.execute('''
    CREATE TABLE ciudades (
      ciudadId TEXT PRIMARY KEY,
      nombre TEXT,
      fecha_creacion TEXT,
      isSynced INTEGER,
      timestamp TEXT
    );
  ''');

  await db.execute('''
    CREATE TABLE series (
      serieId TEXT PRIMARY KEY,
      ciudadId TEXT,
      nombre TEXT,
      fecha_cosecha TEXT,
      fecha_creacion TEXT,
      matriz_alto INTEGER,
      matriz_largo INTEGER,
      superficie REAL,
      isSynced INTEGER,
      timestamp TEXT,
      FOREIGN KEY (ciudadId) REFERENCES ciudades (ciudadId) ON DELETE CASCADE
    );
  ''');

  await db.execute('''
    CREATE TABLE usuarios_locales (
      uid TEXT PRIMARY KEY,
      email TEXT,
      rol TEXT,
      nombre TEXT,
      ciudad TEXT,
      password TEXT,
      timestamp TEXT
    );
  ''');

  await db.execute('''
    CREATE TABLE bloques (
      bloqueId TEXT PRIMARY KEY,
      serieId TEXT,
      nombre TEXT,
      isSynced INTEGER,
      timestamp TEXT,
      FOREIGN KEY (serieId) REFERENCES series (serieId) ON DELETE CASCADE
    );
  ''');

  await db.execute('''
    CREATE TABLE parcelas (
      parcelaId TEXT PRIMARY KEY,
      bloqueId TEXT,
      evaluacion TEXT,
      frecuencia_relativa REAL,
      numero INTEGER,
      numero_ficha TEXT,
      numero_tratamiento INTEGER,
      total_raices INTEGER,
      trabajador_id TEXT,
      tratamiento INTEGER,
      isSynced INTEGER,
      timestamp TEXT,
      FOREIGN KEY (bloqueId) REFERENCES bloques (bloqueId) ON DELETE CASCADE
    );
  ''');

  await db.execute('''
    CREATE TABLE tratamientos_actual (
      parcelaId TEXT PRIMARY KEY,
      fecha TEXT,
      ndvi TEXT,
      observaciones TEXT,
      pesoA REAL,
      pesoB REAL,
      pesoHojas REAL,
      raicesA REAL,
      raicesB REAL,
      trabajador TEXT,
      isSynced INTEGER,
      timestamp TEXT,
      FOREIGN KEY (parcelaId) REFERENCES parcelas (parcelaId) ON DELETE CASCADE
    );
  ''');
}
