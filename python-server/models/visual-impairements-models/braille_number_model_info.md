# Braille Digit Recognition Model: Brief Creation Overview

This project involved creating a Convolutional Neural Network (CNN) to recognize Braille digits (0-9) from images.

## Model Creation Steps:
1.  **Data Preparation:**
    - Raw Braille digit images were collected and organized into classes (0-9).
    - A stable train/validation split (80/20) was created in Google Drive.
    - `ImageDataGenerator` was used to load and preprocess images (rescaling to 0-1, target size 64x64 pixels) into batches.

2.  **Model Architecture:**
    - A sequential CNN model was built using TensorFlow/Keras.
    - It comprises three `Conv2D` layers (32, 64, 128 filters) each followed by `MaxPooling2D`.
    - This is succeeded by a `Flatten` layer, a `Dense` layer (128 units, ReLU activation), a `Dropout` layer (0.4), and a final `Dense` output layer (10 units, Softmax activation) for classification.

3.  **Training:**
    - The model was compiled with the Adam optimizer, `categorical_crossentropy` loss, and `accuracy` as the metric.
    - Training was performed on the prepared datasets with a batch size of 16.
    - `EarlyStopping` was implemented (`patience=6` on `val_accuracy`) to prevent overfitting and ensure the best model weights were saved.

4.  **Performance:**
    - The trained model achieved approximately **88.5% validation accuracy** and 94.2% training accuracy, with a validation loss of 0.392.

5.  **Deployment/Saving:**
    - The final trained model was saved in the Keras format (`braille_number_model.keras`) to Google Drive for future use and prediction.