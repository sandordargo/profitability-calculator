import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:profitability_calculator/property_data.dart';

class PropertyDatabase {
  static final PropertyDatabase _propertyDatabase =
      new PropertyDatabase._internal();

  final String tableName = "Properties";

  static String path;
  Database db;

  bool didInit = false;

  static PropertyDatabase get() {
    return _propertyDatabase;
  }

  PropertyDatabase._internal();

  /// Use this method to access the database, because initialization of the database (it has to go through the method channel)
  Future<Database> _getDb() async {
    if (!didInit) await _init();
    return db;
  }

  Future init() async {
    return await _init();
  }

  Future _init() async {
    // Get a location using path_provider
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = join(documentsDirectory.path, "properties.db");
    PropertyDatabase.path = path;
    db = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      // When creating the db, create the table
      await db.execute("CREATE TABLE $tableName ("
          "ID INTEGER PRIMARY KEY AUTOINCREMENT,"
          "SIMPLE_PRICE INT,"
          "SIMPLE_MONTHLY_RENT INT,"
          "SIMPLE_MONTHLY_CHARGES INT,"
          "DETAILED_PRICE INT,"
          "DETAILED_COMMISSION INT,"
          "DETAILED_NOTARY_FEE INT,"
          "DETAILED_YEARLY_PROPERTY_TAX INT,"
          "DETAILED_MONTHLY_RENT INT,"
          "DETAILED_MONTHLY_CHARGES INT,"
          "URL TEXT,"
          "REMARK TEXT"
          ")");
    });
    didInit = true;
  }

  /// Get a book by its id, if there is not entry for that ID, returns null.
  Future<PropertyData> getBook(int id) async {
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM $tableName WHERE ID = "$id"');
    if (result.length == 0) return null;
    return new PropertyData(
        null, null, null, null, null, null, null, null, null);
  }

  Future insertProperty(PropertyData property) async {
    var db = await _getDb();
    await db.rawInsert(
        'INSERT INTO $tableName(SIMPLE_PRICE, SIMPLE_MONTHLY_RENT, '
        'SIMPLE_MONTHLY_CHARGES, DETAILED_PRICE, DETAILED_COMMISSION, '
        'DETAILED_NOTARY_FEE, DETAILED_YEARLY_PROPERTY_TAX,'
        'DETAILED_MONTHLY_RENT, DETAILED_MONTHLY_CHARGES,'
        'URL, REMARK)'
        ' VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        [
          property.simplePrice,
          property.simpleMonthlyRent,
          property.simpleMonthlyCharges,
          property.detailedPrice,
          property.detailsNotaryFee,
          property.detailedCommission,
          property.detailedMonthlyRent,
          property.detailedMonthlyCharges,
          property.detailedYearlyPropertyTax,
          property.URL,
          property.remark,
        ]);
  }

  Future<List<PropertyData>> getAllProperties() async {
    var db = await _getDb();
    var result = await db.rawQuery('SELECT * FROM $tableName ORDER BY ID ASC');
    if (result.length == 0) return [];
    List<PropertyData> properties = [];
    for (Map<String, dynamic> map in result) {
      properties.add(new PropertyData(
        map["SIMPLE_PRICE"],
        map["SIMPLE_MONTHLY_RENT"],
        map["SIMPLE_MONTHLY_CHARGES"],
        map["DETAILED_PRICE"],
        map["DETAILED_COMMISSION"],
        map["DETAILED_NOTARY_FEE"],
        map["DETAILED_YEARLY_PROPERTY_TAX"],
        map["DETAILED_MONTHLY_RENT"],
        map["DETAILED_MONTHLY_CHARGES"],
        map["URL"],
        map["REMARK"],
        map["ID"],
      ));
    }
    return properties;
  }

  void deleteDrink(PropertyData propertyData) {
    db.delete(tableName, where: "ID = ?", whereArgs: [propertyData.id]);
  }

  void deleteAll() {
    db.delete(tableName);
  }

  Future updateProperty(PropertyData property) async {
    var db = await _getDb();
    await db.rawUpdate(
        'UPDATE $tableName SET SIMPLE_PRICE = ?, SIMPLE_MONTHLY_RENT = ?, '
        'SIMPLE_MONTHLY_CHARGES = ?, DETAILED_PRICE = ?, '
        'DETAILED_COMMISSION = ?, DETAILED_NOTARY_FEE = ?, '
        'DETAILED_YEARLY_PROPERTY_TAX = ?, DETAILED_MONTHLY_RENT = ?, '
        'DETAILED_MONTHLY_CHARGES = ?, URL = ?, REMARK = ?'
        ' WHERE ID = ?',
        [
          property.simplePrice,
          property.simpleMonthlyRent,
          property.simpleMonthlyCharges,
          property.detailedPrice,
          property.detailsNotaryFee,
          property.detailedCommission,
          property.detailedMonthlyRent,
          property.detailedMonthlyCharges,
          property.detailedYearlyPropertyTax,
          property.URL,
          property.remark,
          property.id,
        ]);
    // check result!
  }

  Future upsertDrink(PropertyData property) async {
    return property.id == null ? insertProperty(property) : updateProperty(property);
  }

  Future close() async {
    var db = await _getDb();
    return db.close();
  }
}
