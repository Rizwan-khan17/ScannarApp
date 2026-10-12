import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw; // PDF layout ke liye package
import 'package:path_provider/path_provider.dart'; // Phone directory access karne ke liye
import 'package:open_file/open_file.dart'; // PDF open karne ke liye
import '../models/document_model.dart'; // Data Model import

// ============================================================================
// FILE: lib/providers/scan_provider.dart
// CONNECTS WITH:
// 1. main.dart (Wahan ChangeNotifierProvider ke zariye register hota hai)
// 2. home_screen.dart & document_detail_screen.dart (UI screens is ke methods call karti hain)
// 3. document_model.dart (Data list maintain karne ke liye)
// ============================================================================

class ScanProvider extends ChangeNotifier {
  // Scanned documents ki private memory list
  final List<DocumentModel> _documents = [];

  // ImagePicker instance: Camera aur Gallery access karne ke liye
  final ImagePicker _picker = ImagePicker();

  // Getter: External UI screens is list ko read karne ke liye access karti hain
  List<DocumentModel> get documents => _documents;

  // --------------------------------------------------------------------------
  // LOGIC 1: Camera se photo click karke naya Document banana
  // --------------------------------------------------------------------------
  Future<void> scanDocumentFromCamera() async {
    // Phone ka camera trigger karke single image pick karte hain
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      // Naya DocumentModel instance create kar rahe hain
      final newDoc = DocumentModel(
        id: DateTime.now().toString(),
        title: 'CamScanner_${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}_${DateTime.now().second}',
        dateCreated: DateTime.now(),
        imageFiles: [File(photo.path)], // Captured photo ko file list me dala
      );

      // Latest scanned document ko sab se upar (Index 0 par) insert karte hain
      _documents.insert(0, newDoc);

      // CRITICAL STEP: notifyListeners() UI ko batata hai ke naya document aya hai
      // Is se HomeScreen automatic update ho jati hai!
      notifyListeners();
    }
  }

  // --------------------------------------------------------------------------
  // LOGIC 2: Gallery se multiple images import karke Document/Batch banana
  // --------------------------------------------------------------------------
  Future<void> importImagesFromGallery() async {
    // Gallery se ek sath multiple images select karne ke liye pickMultiImage()
    final List<XFile> selectedImages = await _picker.pickMultiImage();

    if (selectedImages.isNotEmpty) {
      // XFile objects ko standard File objects me convert kar rahe hain
      final List<File> files = selectedImages.map((e) => File(e.path)).toList();

      // Multi-page Document model create kiya
      final newDoc = DocumentModel(
        id: DateTime.now().toString(),
        title: 'Doc_${DateTime.now().millisecondsSinceEpoch}',
        dateCreated: DateTime.now(),
        imageFiles: files,
      );

      _documents.insert(0, newDoc);
      notifyListeners(); // UI ko refresh karne ke liye
    }
  }

  // --------------------------------------------------------------------------
  // LOGIC 3: Document ki images ko PDF me convert karke Open/Share karna
  // --------------------------------------------------------------------------
  Future<void> generateAndOpenPdf(DocumentModel doc) async {
    // Empty PDF document create kiya
    final pdf = pw.Document();

    // Document ki har image par loop chalayenge aur PDF me single page add karenge
    for (var imageFile in doc.imageFiles) {
      final image = pw.MemoryImage(imageFile.readAsBytesSync());

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image), // Image ko PDF page par center fit karna
            );
          },
        ),
      );
    }

    // Temporary storage path jahan PDF compile hoke save hogi
    final output = await getTemporaryDirectory();
    final file = File("${output.path}/${doc.title}.pdf");

    // Memory se binary PDF data file me write kar rahe hain
    await file.writeAsBytes(await pdf.save());

    // Phone ke native PDF viewer se PDF file open kar dena
    await OpenFile.open(file.path);
  }
}