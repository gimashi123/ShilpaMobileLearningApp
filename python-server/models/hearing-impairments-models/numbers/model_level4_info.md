Model Description

The system is designed to recognize hand sign numbers from video sequences. Instead of training directly on raw images, the model uses hand landmark coordinates extracted from each frame using MediaPipe Hands. This approach reduces image complexity and focuses the model on the geometric structure of the hand.

1. Data Representation

Each video is converted into a sequence of hand landmark vectors.

MediaPipe detects 21 hand landmarks for each frame.

Each landmark contains three spatial coordinates (x, y, z).

Therefore, the feature vector for one frame is:

21
 landmarks
×
3
 coordinates
=
63
 features
21 landmarks×3 coordinates=63 features

To represent temporal motion, a fixed sequence length of 40 frames is used.

So each training sample has the shape:

(40, 63)

Meaning:

40 → number of frames in the sequence

63 → number of features per frame

2. Data Preprocessing and Augmentation

Before training, the dataset undergoes preprocessing steps:

Landmark extraction from each video frame

Sequence normalization to maintain equal length

Data augmentation, including:

Gaussian noise addition

Temporal shifting

Minor spatial variation

These steps help increase dataset diversity and improve model generalization.

3. Model Architecture

The model uses a Long Short-Term Memory (LSTM) neural network, which is suitable for learning temporal patterns in sequential data.

Typical architecture used in your notebook:

LSTM Layer

Input shape: (40, 63)

Captures temporal relationships between hand movements.

Dropout Layer

Reduces overfitting during training.

Dense Layer

Learns high-level feature representations.

Softmax Output Layer

Produces probability scores for each sign class.

The final output corresponds to the predicted sign number class.

4. Training Process

The model is trained using:

Categorical cross-entropy loss

Adam optimizer

Multiple epochs to learn temporal patterns in sign gestures.

The training dataset consists of video samples organized by class folders, where each folder represents a specific sign number.

5. Prediction Process

During inference:

A video is captured or uploaded.

MediaPipe extracts hand landmarks for each frame.

The sequence of landmarks is converted into a (40, 63) tensor.

The trained LSTM model predicts the most probable sign class.

The class with the highest probability is returned as the predicted number.

6. Purpose of the Model

The model enables automatic recognition of sign-based numerical gestures, which can be integrated into applications supporting accessible education tools, such as the inclusive learning system you are developing.