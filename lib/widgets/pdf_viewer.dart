import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// A widget to display a PDF from a network URL.
class PDFViewerPage extends StatefulWidget {
  final String? pdfUrl;
  final String title;

  const PDFViewerPage({
    super.key,
    required this.pdfUrl,
    this.title = 'View Document',
  });

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage> {
  String? _localPdfPath;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    if (widget.pdfUrl == null || widget.pdfUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'No PDF document is available to display.';
      });
    } else {
      _loadPdf();
    }
  }

  Future<void> _loadPdf() async {
    try {
      final uri = Uri.parse(widget.pdfUrl!);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/temp.pdf');
        await file.writeAsBytes(response.bodyBytes);
        setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF (Status code: ${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading PDF: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading PDF...'),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return _buildErrorPlaceholder(_errorMessage);
    }

    if (_localPdfPath != null) {
      return PDFView(
        filePath: _localPdfPath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: false,
        pageFling: true,
        onError: (error) {
          setState(() {
            _errorMessage = 'Error displaying PDF: $error';
          });
        },
      );
    }

    return _buildErrorPlaceholder('An unknown error occurred.');
  }

  Widget _buildErrorPlaceholder(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 24),
            Text(
              'Failed to load document',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}