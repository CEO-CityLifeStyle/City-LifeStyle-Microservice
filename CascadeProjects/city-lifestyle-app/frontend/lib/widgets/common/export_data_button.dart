import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class ExportDataButton extends StatelessWidget {
  final Map<String, dynamic> data;
  final String fileName;
  final String buttonText;
  final IconData icon;

  const ExportDataButton({
    Key? key,
    required this.data,
    required this.fileName,
    this.buttonText = 'Export Data',
    this.icon = Icons.download,
  }) : super(key: key);

  Future<void> _exportData() async {
    try {
      // Convert data to JSON string
      final jsonData = jsonEncode(data);
      
      // Get the save location from the user
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Export File',
        fileName: fileName,
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (outputFile != null) {
        // Ensure the file has .json extension
        if (!outputFile.toLowerCase().endsWith('.json')) {
          outputFile = '$outputFile.json';
        }

        // Write the data to the file
        final file = File(outputFile);
        await file.writeAsString(jsonData);
      }
    } catch (e) {
      debugPrint('Error exporting data: $e');
      // Handle error (you might want to show a snackbar or dialog)
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _exportData,
      icon: Icon(icon),
      label: Text(buttonText),
    );
  }
}
