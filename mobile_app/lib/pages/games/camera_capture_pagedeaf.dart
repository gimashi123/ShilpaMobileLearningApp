import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PredictVideoPage extends StatefulWidget {
  final String apiBaseUrl; 

  const PredictVideoPage({
    super.key,
    required this.apiBaseUrl,
  });

  @override
  State<PredictVideoPage> createState() => _PredictVideoPageState();
}

class _PredictVideoPageState extends State<PredictVideoPage> {
  File? _videoFile;
  bool _loading = false;

  Map<String, dynamic>? _result;
  String? _error;

  Future<void> _pickVideo() async {
    setState(() {
      _error = null;
      _result = null;
    });

    final res = await FilePicker.platform.pickFiles(
      type: FileType.video,
      allowMultiple: false,
    );

    if (res == null || res.files.isEmpty) return;

    final path = res.files.single.path;
    if (path == null) {
      setState(() => _error = "Could not read selected video path.");
      return;
    }

    setState(() {
      _videoFile = File(path);
    });
  }

  Future<void> _uploadAndPredict() async {
    if (_videoFile == null) {
      setState(() => _error = "Please select a video first.");
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final uri = Uri.parse("${widget.apiBaseUrl}/api/hearing-impairment/predict-video");

      final req = http.MultipartRequest("POST", uri);

      // MUST be "video" (same as your React: formData.append("video", video))
      req.files.add(await http.MultipartFile.fromPath("video", _videoFile!.path));

      final streamed = await req.send();
      final resp = await http.Response.fromStream(streamed);

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw Exception(resp.body.isNotEmpty ? resp.body : "HTTP ${resp.statusCode}");
      }

      final data = jsonDecode(resp.body);

      if (data is! Map<String, dynamic>) {
        throw Exception("Invalid JSON response (expected an object).");
      }

      setState(() => _result = data);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _buildResultCard() {
    final prediction = _result?["prediction"];
    final confidence = _result?["confidence"];
    final success = _result?["success"];
    final message = _result?["message"];
    final confDouble = confidence is double ? confidence : 
                      confidence is int ? confidence.toDouble() : 
                      confidence is String ? double.tryParse(confidence) : 0.0;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: success == true
              ? [const Color(0xFF11998E), const Color(0xFF38EF7D)]
              : [const Color(0xFFFF416C), const Color(0xFFFF4B2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    success == true ? Icons.check_circle : Icons.error,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "ප්‍රතිඵලය",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black26,
                        offset: Offset(1, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Main Result
            _buildResultItem(
              "🔢 පිළිතුර",
              prediction?.toString() ?? "N/A",
              Colors.white,
            ),
            const SizedBox(height: 16),

            // Confidence with progress bar
            _buildConfidenceSection(confDouble ?? 0.0),
            const SizedBox(height: 16),

            // Status
            _buildResultItem(
              "📊 තත්වය",
              success == true ? "සාර්ථකයි" : "අසාර්ථකයි",
              success == true ? const Color(0xFFC8F7C5) : const Color(0xFFFFCCCB),
            ),
            const SizedBox(height: 16),

            // Message if exists
            if (message != null && message.toString().isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info, color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            message.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: valueColor,
              shadows: const [
                Shadow(
                  blurRadius: 2,
                  color: Colors.black26,
                  offset: Offset(1, 1),
                ),
              ],
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceSection(double confidence) {
    final percentage = (confidence * 100).clamp(0, 100);
    Color progressColor;
    
    if (percentage >= 80) {
      progressColor = const Color(0xFF4CAF50);
    } else if (percentage >= 60) {
      progressColor = const Color(0xFFFFC107);
    } else {
      progressColor = const Color(0xFFF44336);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "🎯 විශ්වාසනීයත්වය",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            Text(
              "${percentage.toStringAsFixed(1)}%",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 12,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Stack(
            children: [
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withOpacity(0.8),
                        progressColor,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.1),
              const Color(0xFF764BA2).withOpacity(0.08),
              const Color(0xFFFFF8E1).withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.arrow_back, color: Color(0xFF2D1B69)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "ගණිත අභියෝගය",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2D1B69),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 68),
                  child: Text(
                    "ඔබගේ වීඩියෝව උඩුගත කර පිළිතුරු ලබාගන්න",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.deepPurple.withOpacity(0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Video Selection Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white.withOpacity(0.8),
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.video_camera_back_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "වීඩියෝව තෝරන්න",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF2D1B69),
                                    ),
                                  ),
                                  Text(
                                    _videoFile == null
                                        ? "කරුණාකර වීඩියෝවක් තෝරන්න"
                                        : "තෝරාගත් වීඩියෝව:",
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.deepPurple.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Video info and buttons
                        if (_videoFile != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F0FF),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.deepPurple.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.video_file, color: Color(0xFF667EEA)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _videoFile!.path.split(Platform.pathSeparator).last,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2D1B69),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 20),

                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _pickVideo,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE3F2FD),
                                  foregroundColor: const Color(0xFF1976D2),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                icon: Icon(
                                  _videoFile == null
                                      ? Icons.video_library
                                      : Icons.change_circle,
                                  size: 22,
                                ),
                                label: Text(
                                  _videoFile == null ? "වීඩියෝව තෝරන්න" : "වෙනස් කරන්න",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _loading ? null : _uploadAndPredict,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF4CAF50),
                                  foregroundColor: Colors.white,
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shadowColor: Colors.green.withOpacity(0.4),
                                ),
                                icon: _loading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.cloud_upload, size: 22),
                                label: Text(
                                  _loading ? "පරීක්ෂා කරමින්..." : "උඩුගත කර පරීක්ෂා කරන්න",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Result Section
                if (_result != null)
                  Expanded(
                    child: SingleChildScrollView(
                      child: _buildResultCard(),
                    ),
                  ),

                if (_error != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "දෝෂයක් ඇති විය",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _error!,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_result == null && _error == null) ...[
                  const Spacer(),
                  Column(
                    children: [
                      Icon(
                        Icons.video_camera_front_rounded,
                        size: 80,
                        color: Colors.deepPurple.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "ගණිත අභියෝගයක වීඩියෝව උඩුගත කරන්න",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "ඔබගේ පිළිතුරු විශ්වාසනීයත්වය සමඟ පෙන්වනු ඇත",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.deepPurple.withOpacity(0.4),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const Spacer(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}