import 'dart:io';

// ============================================================================
// FILE: lib/models/document_model.dart
// CONNECTS WITH: ScanProvider
// PURPOSE: Clear blueprint Data Class jo scanned document ki details hold karti hai.
// ============================================================================

class DocumentModel {
  // Document ki unique ID (timestamp string)
  final String id;

  // Document ka name/title (e.g., CamScanner_12-10-2026)
  final String title;

  // Kis time scan hua uski Date & Time
  final DateTime dateCreated;

  // Scanned photos ki list (Local storage File objects)
  final List<File> imageFiles;

  // Constructor: Naya document banate waqt ye saari cheezein required hongi
  DocumentModel({
    required this.id,
    required this.title,
    required this.dateCreated,
    required this.imageFiles,
  });
}