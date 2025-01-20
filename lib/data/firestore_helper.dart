import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:faculty_load/models/species.dart';

class FirestoreHelper {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new item
  Future<void> createItem(Map<String, dynamic> itemData, String collectionPath) async {
    try {
      await _firestore.collection(collectionPath).add(itemData);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Create a new item with a custom document ID
  Future<void> createItemWithCustomID(String docId, Map<String, dynamic> itemData, String collectionPath) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).set(itemData);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Read an item
  Future<DocumentSnapshot> readItem(String docId, String collectionPath) async {
    try {
      return await _firestore.collection(collectionPath).doc(docId).get();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Read data matching multiple attributes
  Future<List<DocumentSnapshot>> readItemsWithAttributes(String collectionPath, Map<String, dynamic> attributes) async {
    try {
      Query query = _firestore.collection(collectionPath);
      attributes.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      QuerySnapshot querySnapshot = await query.get();
      return querySnapshot.docs;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Read data matching multiple attributes
  Future<List<Map<String, dynamic>>> readItemsWithAttributesMap(String collectionPath, Map<String, dynamic> attributes) async {
    try {
      Query query = _firestore.collection(collectionPath);
      attributes.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      QuerySnapshot querySnapshot = await query.get();
      List<Map<String, dynamic>> result = [];

      for (QueryDocumentSnapshot<Object?> documentSnapshot in querySnapshot.docs) {
        // Convert each document snapshot to a Map<String, dynamic>
        Map<String, dynamic> data = documentSnapshot.data() as Map<String, dynamic>;
        data['id'] = documentSnapshot.id;
        result.add(data);
      }

      return result;
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Update an item
  Future<void> updateItem(String docId, Map<String, dynamic> updatedData, String collectionPath) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).update(updatedData);
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Update data that matches specific attributes
  Future<void> updateItemsWithAttributes(String collectionPath, Map<String, dynamic> searchAttributes, Map<String, dynamic> updateData) async {
    try {
      Query query = _firestore.collection(collectionPath);
      searchAttributes.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      QuerySnapshot querySnapshot = await query.get();
      List<DocumentSnapshot> docs = querySnapshot.docs;

      for (var doc in docs) {
        await _firestore.collection(collectionPath).doc(doc.id).update(updateData);
      }
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Delete an item
  Future<void> deleteItem(String docId, String collectionPath) async {
    try {
      await _firestore.collection(collectionPath).doc(docId).delete();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Delete data that matches specific attributes
  Future<void> deleteItemsWithAttributes(String collectionPath, Map<String, dynamic> searchAttributes) async {
    try {
      Query query = _firestore.collection(collectionPath);
      searchAttributes.forEach((key, value) {
        query = query.where(key, isEqualTo: value);
      });

      QuerySnapshot querySnapshot = await query.get();
      List<DocumentSnapshot> docs = querySnapshot.docs;

      for (var doc in docs) {
        await _firestore.collection(collectionPath).doc(doc.id).delete();
      }
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Fetch real-time data
  Stream<QuerySnapshot> stream(String collectionPath) {
    try {
      return _firestore.collection(collectionPath).snapshots();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }

  // Stream<List<Species>> stream2(String collectionPath) {
  //   return _firestore.collection(collectionPath).snapshots().map((snapshot) => snapshot.docs.map((doc) => Species.fromFirestore(doc)).toList());
  // }

  // Stream data matching multiple attributes
  Stream<QuerySnapshot> streamWithAttributes(String collectionPath, Map<String, dynamic> attributes) {
    try {
      print("#################");
      Query query = _firestore.collection(collectionPath);
      attributes.forEach((key, value) {
        if (value != null) {
          query = query.where(key, isEqualTo: value);
        }
      });

      // print(query.snapshots().doc);
      print("#################");

      return query.snapshots();
    } catch (e) {
      print(e.toString());
      rethrow;
    }
  }
}
