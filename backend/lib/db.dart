import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart';

class DbService {
  static Db? _db;

  static Future<Db> get database async {
    if (_db != null && _db!.isConnected) {
      return _db!;
    }

    final mongoUri = Platform.environment['MONGODB_URI'] ??
        'mongodb+srv://Kranhess:5028841971693aA%23@cluster0.rqj6c4k.mongodb.net/uninotes?retryWrites=true&w=majority&appName=Cluster0&safeAtlas=true';

    _db = await Db.create(mongoUri);
    await _db!.open();
    return _db!;
  }

  static Future<DbCollection> usersCollection() async {
    final db = await database;
    return db.collection('users');
  }

  // Doğrulama beklenen, henüz aktif olmayan kayıtlar.
  // Kullanıcı kodu doğru girene kadar burada durur, doğrulanınca
  // usersCollection()'a taşınır ve buradan silinir.
  static Future<DbCollection> pendingRegistrationsCollection() async {
    final db = await database;
    return db.collection('pendingRegistrations');
  }

  static Future<DbCollection> notesCollection() async {
    final db = await database;
    return db.collection('notes');
  }

  static Future<DbCollection> universitiesCollection() async {
    final db = await database;
    return db.collection('universities');
  }

  static Future<DbCollection> departmentsCollection() async {
    final db = await database;
    return db.collection('departments');
  }

  static Future<DbCollection> coursesCollection() async {
    final db = await database;
    return db.collection('courses');
  }
}