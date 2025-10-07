// import 'package:flutter/material.dart';
//
// /// PDF viewer component with placeholder functionality
// class PDFViewer extends StatelessWidget {
//   final String semester;
//   final String? pdfUrl; // Placeholder for future PDF URL
//
//   const PDFViewer({
//     super.key,
//     required this.semester,
//     this.pdfUrl,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Semester $semester Results'),
//         backgroundColor: Theme.of(context).colorScheme.primary,
//         foregroundColor: Colors.white,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.download),
//             onPressed: () {
//               // Placeholder for download functionality
//               ScaffoldMessenger.of(context).showSnackBar(
//                 const SnackBar(content: Text('Download functionality coming soon!')),
//               );
//             },
//           ),
//         ],
//       ),
//       body: pdfUrl == null
//         ? _buildPlaceholder()
//         : _buildPDFViewer(),
//     );
//   }
//
//   Widget _buildPlaceholder() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.picture_as_pdf,
//             size: 80,
//             color: Colors.grey.shade400,
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'No PDF available',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w500,
//               color: Colors.grey.shade600,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Results for Semester $semester have not been uploaded yet',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade500,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPDFViewer() {
//     // Placeholder for actual PDF viewer implementation
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.picture_as_pdf,
//             size: 80,
//             color: Theme.of(context).colorScheme.primary,
//           ),
//           const SizedBox(height: 24),
//           Text(
//             'PDF Viewer',
//             style: TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w500,
//               color: Theme.of(context).colorScheme.primary,
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'PDF viewer implementation coming soon!',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey.shade600,
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
// }