Sign Number Recognition Model
This project develops a deep learning model for real-time recognition of number signs using hand landmark data extracted from videos.

1. Project Goal
The primary objective is to build a robust model that can accurately identify 25 different number signs from video input. This involves capturing hand gestures, extracting key hand landmarks, and classifying the sequence of these landmarks using a recurrent neural network.

2. Dataset
Source: The model was trained on a custom dataset of raw video files, organized into class-specific folders (e.g., '24', '25', '26', etc.) stored in Google Drive (/content/drive/MyDrive/SignNumberModel/raw_videos).

Preprocessing Steps:

Video Renaming: Videos within each class folder were systematically renamed (e.g., 25_video01.mp4).
MediaPipe Landmark Extraction: Each video frame was processed using MediaPipe Hands to detect a single hand and extract 21 2D (x, y) hand landmark coordinates, resulting in a 42-value vector per frame.
Landmark Normalization: For each frame's 42-value landmark vector, the coordinates were normalized:
The wrist landmark (index 0) was used as the origin (0,0).
All other landmarks were scaled relative to the maximum distance from the new origin. This normalization ensures that the model is invariant to hand position and size in the frame.
Uniform Sampling: To create consistent input sequences for the model, each video's sequence of normalized landmark vectors was uniformly sampled or padded to a fixed SEQUENCE_LEN of 30 frames. This transforms each video into a (30, 42) numpy array.
Dataset Size: After preprocessing, the dataset consisted of 267 samples across 25 unique number sign classes. This dataset was split into 80% for training (213 samples) and 20% for testing (54 samples), with stratify=y_idx to maintain class balance.

3. Model Architecture
The classification model is a Bidirectional Long Short-Term Memory (BiLSTM) network implemented using TensorFlow/Keras:

Input Layer: Input(shape=(30, 42)) - Expects sequences of 30 frames, each with 42 landmark coordinates.
First BiLSTM Layer: Bidirectional(LSTM(128, return_sequences=True)) - Processes the input sequence in both forward and backward directions, capturing temporal dependencies. return_sequences=True ensures the output is a sequence.
First Dropout Layer: Dropout(0.3) - Regularization to prevent overfitting by randomly setting 30% of input units to zero at each update during training.
Second BiLSTM Layer: Bidirectional(LSTM(64)) - Further processes the sequence, with return_sequences=False indicating that only the last output of the sequence is passed to the next layer.
Second Dropout Layer: Dropout(0.3).
Dense Layer: Dense(128, activation='relu') - A fully connected layer with ReLU activation.
Output Layer: Dense(25, activation='softmax') - A fully connected output layer with 25 units (one for each class) and a softmax activation function to produce probability distributions over the classes.
4. Training Details
Optimizer: Adam with a learning rate of 0.001.
Loss Function: sparse_categorical_crossentropy (suitable for integer-encoded labels).
Metrics: accuracy.
Epochs: 80.
Batch Size: 8.
Callbacks: EarlyStopping was used with monitor='val_loss' and patience=8 to halt training if validation loss did not improve for 8 consecutive epochs, and restore_best_weights=True to load the weights from the epoch with the best validation loss.
5. Performance
After training, the model's performance on the unseen test set was:

Final Test Accuracy: 75.93%.
Training and validation accuracy/loss plots, as well as a confusion matrix, were generated to visualize the model's learning process and identify misclassifications.

6. Live Prediction Usage
The trained model can be used for live predictions:

Video Capture: A short video (e.g., 4 seconds) of a hand gesture is captured.
Landmark Extraction: MediaPipe is used to extract hand landmarks from the live captured video, similar to the preprocessing step.
Normalization & Sampling: The extracted landmarks are normalized and uniformly sampled/padded to create a (1, 30, 42) input sequence for the model.
Prediction: The model predicts probabilities for each of the 25 classes.
Strict Decision Logic: A strict decision logic is applied with configurable thresholds:
CONF_TH = 0.70: The top predicted probability must be at least 70%.
MARGIN_TH = 0.25: The difference between the top-1 and top-2 predicted probabilities must be at least 25%. If both conditions are met, the class is confidently predicted; otherwise, the result is classified as "UNKNOWN".