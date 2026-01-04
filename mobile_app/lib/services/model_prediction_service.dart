/**
 * Example: How to call the model prediction from the Flutter mobile app
 * 
 * 1. Make HTTP request to the backend:
 * 
 * POST http://your-backend:3000/api/models/hearing-impairment/predict
 * Content-Type: application/json
 * 
 * {
 *   "features": [0.1, 0.2, 0.3, ...],
 *   "description": "optional description"
 * }
 * 
 * 2. Backend will forward to Python server and return the prediction
 * 
 * 3. Response:
 * 
 * {
 *   "success": true,
 *   "prediction": 5,
 *   "confidence": null,
 *   "message": "Prediction completed successfully"
 * }
 */

import 'dart:convert';
import 'package:http/http.dart' as http;

class ModelPredictionService {
  // Backend API URL - Update this to your backend server address
  static const String backendUrl = 'http://your-backend-ip:3000';
  
  /// Call the hearing impairment model for sign number prediction
  /// 
  /// [features]: List of numerical features from your ML pipeline
  /// [description]: Optional description of what the features represent
  /// 
  /// Returns the predicted sign number
  static Future<int?> predictSignNumber({
    required List<double> features,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/models/hearing-impairment/predict'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'features': features,
          if (description != null) 'description': description,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['prediction'] as int;
        } else {
          print('Prediction failed: ${data['message']}');
          return null;
        }
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error calling model prediction: $e');
      return null;
    }
  }

  /// Check if the model service is healthy
  static Future<bool> checkModelHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/models/hearing-impairment/health'),
      ).timeout(
        const Duration(seconds: 5),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Example: Extract features from video or audio
  /// This is a placeholder - implement based on your actual feature extraction logic
  static List<double> extractFeatures({
    required String inputData,
  }) {
    // TODO: Implement actual feature extraction
    // This could involve:
    // - Video frame analysis
    // - Pose estimation
    // - Hand gesture tracking
    // - Audio features
    // etc.
    
    return [0.1, 0.2, 0.3]; // Placeholder
  }
}

// Example usage in a widget:
/*
class PredictionExample extends StatefulWidget {
  @override
  State<PredictionExample> createState() => _PredictionExampleState();
}

class _PredictionExampleState extends State<PredictionExample> {
  int? prediction;
  bool isLoading = false;

  Future<void> makePrediction() async {
    setState(() => isLoading = true);
    
    try {
      // Extract features from your input (video, audio, etc.)
      final features = ModelPredictionService.extractFeatures(
        inputData: 'your-input-data',
      );

      // Get prediction
      final result = await ModelPredictionService.predictSignNumber(
        features: features,
        description: 'Sign number prediction',
      );

      setState(() {
        prediction = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prediction: $result')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: isLoading ? null : makePrediction,
          child: isLoading ? const CircularProgressIndicator() : const Text('Predict'),
        ),
        if (prediction != null) Text('Result: $prediction'),
      ],
    );
  }
}
*/
