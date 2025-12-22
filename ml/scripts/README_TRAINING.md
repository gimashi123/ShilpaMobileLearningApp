# Sign Language Numbers Recognition - Training Guide

This guide will help you train a model to recognize sign language numbers from video data using Google Colab.

## 📋 Prerequisites

1. **Google Colab Account** - Free account is sufficient
2. **Video Data** - Your raw videos organized by number
3. **Google Drive** (optional) - For storing large video datasets

## 📁 Data Organization

Organize your video files in the following structure:

```
data_raw/
├── 1/
│   ├── video1.mp4
│   ├── video2.mp4
│   └── ...
├── 2/
│   ├── video1.mp4
│   └── ...
├── 200/
│   ├── video1.mp4
│   └── ...
└── 210/
    ├── video1.mp4
    └── ...
```

**Important Notes:**
- Each folder should be named with the number it represents (e.g., `1`, `2`, `200`, `210`)
- The script will automatically extract the number from folder names
- Supported video formats: `.mp4`, `.avi`, `.mov`, `.mkv`, `.flv`, `.wmv`
- More videos per number = better model performance

## 🚀 Step-by-Step Instructions

### 1. Open the Notebook in Colab

1. Go to [Google Colab](https://colab.research.google.com/)
2. Click **File** → **Upload notebook**
3. Upload `sign_language_numbers_training.ipynb`

### 2. Upload Your Video Data

You have two options:

#### Option A: Using Google Drive (Recommended for large datasets)

1. Upload your `data_raw` folder to Google Drive
2. In the notebook, uncomment and run the Google Drive mount cell:
   ```python
   from google.colab import drive
   drive.mount('/content/drive')
   !cp -r '/content/drive/MyDrive/path/to/data_raw' /content/data_raw
   ```

#### Option B: Direct Upload (For smaller datasets)

1. Create the directory structure in Colab:
   ```python
   !mkdir -p /content/data_raw
   ```
2. Use the file uploader in the notebook to upload videos
3. Organize them into folders by number

### 3. Configure Settings

Update the configuration cell if needed:
- `DATA_DIR`: Path to your video data (default: `/content/data_raw`)
- `SEQUENCE_LENGTH`: Number of frames per video (default: 30)
- `EPOCHS`: Training epochs (default: 50)
- `BATCH_SIZE`: Batch size (default: 32)

### 4. Run the Notebook

Execute cells in order:

1. **Install Dependencies** - Installs required packages
2. **Import Libraries** - Loads necessary libraries
3. **Configuration** - Sets up paths and parameters
4. **Upload Data** - Loads your video files
5. **Extract Features** - Processes videos with MediaPipe (this may take a while)
6. **Prepare Dataset** - Splits data into train/val/test sets
7. **Build Model** - Creates the LSTM model architecture
8. **Train Model** - Trains the model (this may take hours depending on data size)
9. **Evaluate Model** - Shows performance metrics and visualizations
10. **Save Model** - Saves the trained model
11. **Download Model** - Downloads model files to your computer

### 5. Monitor Training

- Watch the training progress in the output
- Check the training history plots
- Review the confusion matrix after training
- The model will automatically save the best version based on validation accuracy

## 📊 Understanding the Output

### Training Metrics

- **Loss**: Should decrease over time
- **Accuracy**: Should increase over time
- **Validation metrics**: Should track training metrics closely (if not, you may have overfitting)

### Model Files

After training, you'll get:
- `sign_language_numbers_model.h5` - The trained model
- `label_encoder.pkl` - Maps class indices to numbers
- `training_log.csv` - Training history
- `training_history.png` - Training curves
- `confusion_matrix.png` - Performance visualization

## 🔧 Troubleshooting

### Issue: "No module named 'mediapipe'"
**Solution**: Make sure you ran the installation cell first

### Issue: "Could not extract number from folder"
**Solution**: Ensure folder names contain numbers (e.g., `1`, `2`, `number_200`)

### Issue: "Out of memory"
**Solution**: 
- Reduce `BATCH_SIZE`
- Reduce `SEQUENCE_LENGTH`
- Process fewer videos at once

### Issue: Low accuracy
**Solution**:
- Add more training videos per number
- Ensure videos are clear and consistent
- Increase training epochs
- Check if videos are properly labeled

### Issue: Videos not processing
**Solution**:
- Check video format is supported
- Verify video files are not corrupted
- Ensure MediaPipe can detect hands/pose in videos

## 💡 Tips for Better Results

1. **Data Quality**:
   - Use clear, well-lit videos
   - Ensure consistent signing style
   - Include multiple signers if possible

2. **Data Quantity**:
   - Aim for at least 10-20 videos per number
   - More data = better generalization

3. **Training**:
   - Start with fewer epochs to test
   - Use GPU runtime in Colab (Runtime → Change runtime type → GPU)
   - Monitor validation loss to avoid overfitting

4. **Model Tuning**:
   - Adjust `SEQUENCE_LENGTH` based on video duration
   - Experiment with different LSTM layer sizes
   - Try different learning rates

## 📱 Using the Trained Model

After training, you can use the model for inference:

```python
# Load the model
model = keras.models.load_model('sign_language_numbers_model.h5')
with open('label_encoder.pkl', 'rb') as f:
    label_encoder = pickle.load(f)

# Predict from a video
predicted_number, confidence = predict_sign_language_number(
    'path/to/video.mp4', 
    model, 
    label_encoder
)
print(f"Predicted: {predicted_number}, Confidence: {confidence:.2%}")
```

## 📚 Additional Resources

- [MediaPipe Documentation](https://mediapipe.dev/)
- [TensorFlow/Keras Guide](https://www.tensorflow.org/guide/keras)
- [LSTM Networks](https://www.tensorflow.org/api_docs/python/tf/keras/layers/LSTM)

## ⚠️ Important Notes

- Colab sessions timeout after inactivity - save your work frequently
- Free Colab has usage limits - consider Colab Pro for longer sessions
- Processed data is saved - you can reload it to avoid reprocessing
- Model files can be large - download them before session ends

## 🎯 Next Steps

After training:
1. Test the model on new videos
2. Fine-tune if needed
3. Integrate into your mobile app
4. Deploy for real-time inference

Good luck with your training! 🚀



