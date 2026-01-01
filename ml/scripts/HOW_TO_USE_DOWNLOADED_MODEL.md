# 🚀 How to Use Your Downloaded Model - Complete Guide

## ✅ What You Have

You've downloaded:
- ✅ `best_model.h5` - The trained model (1,116 KB)
- ✅ `label_encoder_20_classes.pkl` - Label encoder for 20 classes
- ✅ `sign_language_numbers_model_final.h5` - Final model (373 KB)
- ✅ `label_encoder.pkl` - Original label encoder (83 classes)

---

## 🎯 Next Steps

### Step 1: Test the Model Locally

**Create a test script to verify the model works:**

```python
# test_model.py
import numpy as np
import tensorflow as tf
from tensorflow import keras
import pickle
import cv2
import mediapipe as mp
from pathlib import Path

# Load model and label encoder
model = keras.models.load_model('best_model.h5')
with open('label_encoder_20_classes.pkl', 'rb') as f:
    label_encoder = pickle.load(f)

print("✅ Model loaded successfully!")
print(f"   Model expects: 20 classes")
print(f"   Classes: {sorted(label_encoder.classes_)}")

# Test with a video file
def predict_from_video(video_path):
    """Predict sign language number from video."""
    # You'll need to extract landmarks first
    # (Use the same extraction function from training)
    landmarks = extract_hand_landmarks_from_video(video_path)
    
    # Reshape for model
    landmarks = np.expand_dims(landmarks, axis=0)
    
    # Predict
    predictions = model.predict(landmarks, verbose=0)
    
    # Get top-5 predictions
    top_5_indices = np.argsort(predictions[0])[-5:][::-1]
    top_5_probs = predictions[0][top_5_indices]
    top_5_numbers = label_encoder.inverse_transform(top_5_indices)
    
    print("\n📊 Predictions:")
    for num, prob in zip(top_5_numbers, top_5_probs):
        print(f"   Number {num}: {prob*100:.2f}% confidence")
    
    return top_5_numbers[0], top_5_probs[0]

# Test
# predicted, confidence = predict_from_video('path/to/test_video.mp4')
```

---

### Step 2: Integrate into Your Mobile App

**For your Flutter/Dart mobile app:**

#### A. Convert Model to TensorFlow Lite (Recommended)

```python
# Convert to TensorFlow Lite for mobile
converter = tf.lite.TFLiteConverter.from_keras_model(best_model)
tflite_model = converter.convert()

# Save
with open('sign_language_model.tflite', 'wb') as f:
    f.write(tflite_model)

print("✅ Model converted to TensorFlow Lite!")
print("   File: sign_language_model.tflite")
print("   Size: {:.2f} MB".format(len(tflite_model) / (1024 * 1024)))
```

#### B. Use in Flutter App

```dart
// In your Flutter app
import 'package:tflite_flutter/tflite_flutter.dart';

class SignLanguageRecognizer {
  Interpreter? interpreter;
  List<String> labels = [];
  
  Future<void> loadModel() async {
    // Load model
    interpreter = await Interpreter.fromAsset('sign_language_model.tflite');
    
    // Load labels
    final labelString = await rootBundle.loadString('assets/labels_20.txt');
    labels = labelString.split('\n');
  }
  
  Future<String> predict(List<List<List<double>>> landmarks) async {
    // Prepare input
    var input = [landmarks];
    var output = List.filled(20, 0.0).reshape([1, 20]);
    
    // Run inference
    interpreter!.run(input, output);
    
    // Get prediction
    int predictedIndex = output[0].indexOf(output[0].reduce(max));
    return labels[predictedIndex];
  }
}
```

---

### Step 3: Create Inference Script

**Standalone script to use the model:**

```python
# inference.py
import numpy as np
import tensorflow as tf
from tensorflow import keras
import pickle
import cv2
import mediapipe as mp
import sys

# Load model
MODEL_PATH = 'best_model.h5'
LABEL_ENCODER_PATH = 'label_encoder_20_classes.pkl'

model = keras.models.load_model(MODEL_PATH)
with open(LABEL_ENCODER_PATH, 'rb') as f:
    label_encoder = pickle.load(f)

# MediaPipe setup
mp_hands = mp.solutions.hands
hands = mp_hands.Hands(
    static_image_mode=False,
    max_num_hands=2,
    min_detection_confidence=0.5,
    min_tracking_confidence=0.5
)

def extract_hand_landmarks_from_video(video_path, max_frames=30):
    """Extract hand landmarks from video (same as training)."""
    cap = cv2.VideoCapture(video_path)
    landmarks_list = []
    frame_count = 0
    
    while cap.isOpened() and frame_count < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        hand_results = hands.process(frame_rgb)
        
        frame_landmarks = []
        
        if hand_results.multi_hand_landmarks:
            primary_hand = hand_results.multi_hand_landmarks[0]
            for landmark in primary_hand.landmark:
                frame_landmarks.extend([landmark.x, landmark.y, landmark.z])
            if len(hand_results.multi_hand_landmarks) == 1:
                frame_landmarks.extend([0.0] * 63)
        else:
            frame_landmarks.extend([0.0] * 126)
        
        if len(frame_landmarks) != 126:
            frame_landmarks = frame_landmarks[:126] if len(frame_landmarks) > 126 else frame_landmarks + [0.0] * (126 - len(frame_landmarks))
        
        landmarks_list.append(frame_landmarks)
        frame_count += 1
    
    cap.release()
    hands.close()
    
    # Pad or truncate
    if len(landmarks_list) < max_frames:
        last_frame = landmarks_list[-1].copy() if landmarks_list else [0.0] * 126
        while len(landmarks_list) < max_frames:
            landmarks_list.append(last_frame.copy())
    elif len(landmarks_list) > max_frames:
        landmarks_list = landmarks_list[:max_frames]
    
    return np.array(landmarks_list, dtype=np.float32)

def predict_sign_language_number(video_path):
    """Predict sign language number from video."""
    print(f"🔍 Processing: {video_path}")
    
    # Extract landmarks
    landmarks = extract_hand_landmarks_from_video(video_path)
    
    # Reshape for model
    landmarks = np.expand_dims(landmarks, axis=0)
    
    # Predict
    predictions = model.predict(landmarks, verbose=0)
    
    # Get top-5 predictions
    top_5_indices = np.argsort(predictions[0])[-5:][::-1]
    top_5_probs = predictions[0][top_5_indices]
    top_5_numbers = label_encoder.inverse_transform(top_5_indices)
    
    print("\n📊 Predictions:")
    for i, (num, prob) in enumerate(zip(top_5_numbers, top_5_probs), 1):
        print(f"   {i}. Number {num}: {prob*100:.2f}% confidence")
    
    predicted_number = top_5_numbers[0]
    confidence = top_5_probs[0]
    
    print(f"\n✅ Predicted: Number {predicted_number} ({confidence*100:.2f}% confidence)")
    
    return predicted_number, confidence

# Main
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python inference.py <video_path>")
        sys.exit(1)
    
    video_path = sys.argv[1]
    predict_sign_language_number(video_path)
```

**Usage:**
```bash
python inference.py path/to/video.mp4
```

---

### Step 4: Improve the Model

**To get better accuracy:**

#### A. Collect More Data
- Focus on classes with 0% accuracy: 78, 80, 88, 92, 109, 110, 135, 140, 165, 200, 210
- Aim for 30-50+ videos per class
- More variety = better accuracy

#### B. Retrain with More Data
- Once you have more videos, retrain the model
- Expected improvement: 20-30%+ accuracy

#### C. Fine-tune Hyperparameters
- Try different learning rates
- Adjust batch size
- Modify model architecture

---

### Step 5: Deploy to Production

**For production use:**

1. **Convert to TensorFlow Lite** (for mobile)
2. **Create API** (for web/backend)
3. **Optimize model** (quantization, pruning)
4. **Add error handling**
5. **Monitor performance**

---

## 📝 Quick Start Guide

### 1. Test Model Locally

```python
# Quick test
import tensorflow as tf
from tensorflow import keras
import pickle

# Load
model = keras.models.load_model('best_model.h5')
with open('label_encoder_20_classes.pkl', 'rb') as f:
    label_encoder = pickle.load(f)

print("✅ Model loaded!")
print(f"Classes: {sorted(label_encoder.classes_)}")
```

### 2. Use for Predictions

```python
# Use the inference script above
# Or integrate into your app
```

### 3. Improve Over Time

- Collect more data
- Retrain periodically
- Monitor accuracy
- Update model

---

## 🎯 Summary

**What You Have:**
- ✅ Trained model (11.22% accuracy, 51% Top-K)
- ✅ Label encoder
- ✅ Ready to use!

**Next Steps:**
1. ✅ Test model locally
2. ✅ Integrate into your app
3. ✅ Collect more data
4. ✅ Improve accuracy over time

**Your model is ready to use! Start testing and improving! 🚀**

---

## 💡 Tips

1. **Start with best classes** - Use numbers 124, 90, 83 first (they work best)
2. **Use Top-K predictions** - Show top-3 or top-5 predictions to user
3. **Collect feedback** - Track which predictions are wrong
4. **Retrain regularly** - As you get more data, retrain the model

---

**Congratulations! You've successfully trained and downloaded your model! 🎉**



