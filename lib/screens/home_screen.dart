import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/scan_provider.dart'; // Provider logic import
import 'document_detail_screen.dart'; // Detail View screen import

// ============================================================================
// FILE: lib/screens/home_screen.dart
// CONNECTS WITH:
// 1. ScanProvider (Scan methods trigger karne aur recents list render karne ke liye)
// 2. DocumentDetailScreen (Card tap hone par navigate karne ke liye)
// ============================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ScanProvider ka active instance le rahe hain.
    // Is object se hum state read kar saktay hain aur functions call kar saktay hain.
    final scanProvider = Provider.of<ScanProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('CamScanner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------------------
            // SECTION 1: Top Quick Actions Bar (Smart Scan, Gallery Import etc.)
            // ----------------------------------------------------------------
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF1E1E1E),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(), // Parent SingleChildScrollView scroll handle karega
                crossAxisCount: 4,
                children: [
                  // Camera Scan Trigger
                  _buildQuickAction(Icons.qr_code_scanner, 'Smart Scan', () {
                    scanProvider.scanDocumentFromCamera();
                  }),
                  _buildQuickAction(Icons.picture_as_pdf, 'PDF Tools', () {}),
                  // Gallery Import Trigger
                  _buildQuickAction(Icons.image, 'Import Images', () {
                    scanProvider.importImagesFromGallery();
                  }),
                  _buildQuickAction(Icons.folder, 'Import Files', () {}),
                  _buildQuickAction(Icons.badge, 'ID Cards', () {}),
                  _buildQuickAction(Icons.text_fields, 'Extract Text', () {}),
                  _buildQuickAction(Icons.auto_awesome, 'Solver AI', () {}),
                  _buildQuickAction(Icons.grid_view, 'All', () {}),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Recents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),

            // ----------------------------------------------------------------
            // SECTION 2: Dynamic List of Scanned Documents
            // ----------------------------------------------------------------
            scanProvider.documents.isEmpty
                ? const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text('Abhi tak koi document scan nahi hua.'),
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: scanProvider.documents.length, // List length
              itemBuilder: (context, index) {
                // Specific index ka document object
                final doc = scanProvider.documents[index];

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  color: const Color(0xFF2C2C2C),
                  child: ListTile(
                    // First image thumbnail display karna
                    leading: doc.imageFiles.isNotEmpty
                        ? Image.file(
                      doc.imageFiles.first,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    )
                        : const Icon(Icons.description),
                    title: Text(doc.title),
                    subtitle: Text(
                      '${doc.dateCreated.day}/${doc.dateCreated.month}/${doc.dateCreated.year}  |  ${doc.imageFiles.length} Pages',
                    ),
                    // Card tap hone par DocumentDetailScreen par navigate karna
                    // aur clicked 'doc' object ko explicitly pass karna
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DocumentDetailScreen(document: doc),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // ----------------------------------------------------------------------
      // SECTION 3: Floating Camera Button (Bottom Right)
      // ----------------------------------------------------------------------
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00BFA5), // Teal Color
        onPressed: () {
          scanProvider.scanDocumentFromCamera(); // Camera launcher
        },
        child: const Icon(Icons.camera_alt, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF1E1E1E),
        selectedItemColor: const Color(0xFF00BFA5),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Files'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Tools'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }

  // Quick action icon item helper method
  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF2C2C2C),
            child: Icon(icon, color: const Color(0xFF00BFA5)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}