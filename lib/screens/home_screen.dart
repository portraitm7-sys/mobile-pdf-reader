import 'package:flutter/material.dart';

import '../models/pdf_item.dart';
import '../services/pdf_library_controller.dart';
import '../widgets/pdf_tile.dart';
import 'reader_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.controller,
  });

  final PdfLibraryController controller;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends
