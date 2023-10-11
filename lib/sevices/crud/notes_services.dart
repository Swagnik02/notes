import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class DatabaseAlreadyOpenException implements Exception {}

class DatabaseIsNotOpen implements Exception {}

class UnableToGetDoccumentsDirectory implements Exception {}

class CouldNotDeleteUser implements Exception {}

class UserAlreadyExists implements Exception {}

// constants
const dbName = 'notes.db';

class NoteService {
  Database? _db;

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }

    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db = await openDatabase(dbPath);
      _db = db;
      // CREATE USER TABLE
      await db.execute(createUserTable);
      // CREATE NOTE TABLE
      await db.execute(createNoteTable);
    } on MissingPlatformDirectoryException {
      throw UnableToGetDoccumentsDirectory();
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> deleteUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Future<DatabaseUser> createUser({required String email}) async {
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email == ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }
    final userId = await db.insert(userTable, {
      emailColumn: email.toUpperCase(),
    });

    return DatabaseUser(
      id: userId,
      email: email,
    );
  }
}

@immutable
class DatabaseUser {
  final int id;
  final String email;
  const DatabaseUser({
    required this.id,
    required this.email,
  });

  DatabaseUser.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        email = map[emailColumn] as String;

  @override
  String toString() => 'Person, ID = $id, email = $email';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNote {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  const DatabaseNote({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  DatabaseNote.fromRow(Map<String, Object?> map)
      : id = map[idColumn] as int,
        userId = map[userIdColumn] as int,
        text = map[textColumn] as String,
        isSyncedWithCloud =
            (map[isSyncedWithCloudColumn] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id, userID = $userId,isSyncedWithCloud = $isSyncedWithCloud, text =$text';

  @override
  bool operator ==(covariant DatabaseNote other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// constants
const userTable = 'user';
const noteTable = 'note';

const idColumn = 'id';
const emailColumn = 'email';

const userIdColumn = 'user_id';
const textColumn = 'text';
const isSyncedWithCloudColumn = 'is_synced_with_cloud';

// SQL QUERIES
const createUserTable = '''
                CREATE TABLE IF NOT EXISTS "user" (
                	"id"	INTEGER NOT NULL,
                	"email"	TEXT NOT NULL UNIQUE,
                	PRIMARY KEY("id" AUTOINCREMENT)
                );
      ''';
const createNoteTable = '''
              CREATE TABLE IF NOT EXISTS "note" (
              	"id"	INTEGER NOT NULL,
              	"user_id"	INTEGER NOT NULL,
              	"text"	TEXT,
              	"is_synced_with_cloud"	INTEGER NOT NULL DEFAULT 0,
              	FOREIGN KEY("user_id") REFERENCES "user"("id"),
              	PRIMARY KEY("id" AUTOINCREMENT)
              );
      ''';
