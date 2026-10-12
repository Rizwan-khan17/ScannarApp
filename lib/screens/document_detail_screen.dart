import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/document_model.dart'; // Document Data Object
import '../providers/scan_provider.dart'; // PDF Generation Trigger

// ============================================================================
// FILE: lib/screens/document_detail_screen.dart
// CONNECTS WITH:
// 1. HomeScreen (Se selected document ka object receive karti hai)
// 2. ScanProvider (PDF view/generate karne ke liye method call karti hai)
// ============================================================================

class DocumentDetailScreen extends StatelessWidget {
  // HomeScreen se pass hua specific Document object
  final DocumentModel document;

  const DocumentDetailScreen({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    // Action trigger karne ke liye Provider reference (listen: false kyunki UI listen karna zaruri nahi)
    final scanProvider = Provider.of<ScanProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(document.title),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),

      // ----------------------------------------------------------------------
      // SECTION 1: Document Grid View (CamScanner pages layout)
      // ----------------------------------------------------------------------
      body: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Ek row me 2 document pages
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: document.imageFiles.length, // Selected document ke total pages
        itemBuilder: (context, index) {
          return Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    document.imageFiles[index], // Particular image page
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Page Index Badge (01, 02, 03...)
              Text(
                '0${index + 1}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          );
        },
      ),

      // ----------------------------------------------------------------------
      // SECTION 2: Bottom Navigation Bar (PDF Generate & Share Options)
      // ----------------------------------------------------------------------
      bottomNavigationBar: Container(
        height: 60,
        color: const Color(0xFF1E1E1E),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // PDF Option: Click karne par Provider images ko PDF me compile kar ke viewer me open kar dega
            _buildBottomNavItem(Icons.picture_as_pdf, 'Edit PDF', () {
              scanProvider.generateAndOpenPdf(document);
            }),
            _buildBottomNavItem(Icons.edit, 'Markup', () {}),
            // Page Add Button
            _buildBottomNavItem(Icons.add_a_photo, 'Add', () {
              scanProvider.scanDocumentFromCamera();
            }),
            // Share Option
            _buildBottomNavItem(Icons.share, 'Share', () {
              scanProvider.generateAndOpenPdf(document);
            }),
            _buildBottomNavItem(Icons.more_horiz, 'More', () {}),
          ],
        ),
      ),
    );
  }

  // Helper Widget: Bottom Navigation Action Button
  Widget _buildBottomNavItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10)),
        ],
      ),
    );
  }
}