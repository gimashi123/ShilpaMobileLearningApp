# 🏗️ Step 5: Build and Train the Model - Complete Guide

## ✅ What You've Completed
- [x] Installed packages
- [x] Imported libraries
- [x] Configuration
- [x] Copied data from Google Drive
- [x] Extracted features (1312 samples, hands-only)
- [x] Prepared dataset (917 train, 132 val, 263 test) ✅

---

## 🎯 Step 5A: Build the Model

This step creates the LSTM model architecture for sequence classification.

### Code to Run:

```python
def create_lstm_model(input_shape, num_classes, learning_rate=LEARNING_RATE):
    """
    Create an LSTM-based model for sequence classification.
    """
    model = keras.Sequential([
        # Input layer
        layers.Input(shape=input_shape),
        
        # Normalization
        layers.BatchNormalization(),
        
        # LSTM layers
        layers.LSTM(128, return_sequences=True, dropout=0.3, recurrent_dropout=0.3),
        layers.BatchNormalization(),
        
        layers.LSTM(64, return_sequences=True, dropout=0.3, recurrent_dropout=0.3),
        layers.BatchNormalization(),
        
        layers.LSTM(32, return_sequences=False, dropout=0.3, recurrent_dropout=0.3),
        layers.BatchNormalization(),
        
        # Dense layers
        layers.Dense(128, activation='relu'),
        layers.Dropout(0.5),
        layers.BatchNormalization(),
        
        layers.Dense(64, activation='relu'),
        layers.Dropout(0.5),
        
        # Output layer
        layers.Dense(num_classes, activation='softmax')
    ])
    
    # Compile model
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=learning_rate),
        loss='categorical_crossentropy',
        metrics=['accuracy', 'top_k_categorical_accuracy']
    )
    
    return model


# Build the model
input_shape = (X_train.shape[1], X_train.shape[2])  # (30, 126)
model = create_lstm_model(input_shape, NUM_CLASSES)

# Show model architecture
print("📊 Model Architecture:")
model.summary()
```

**Run it:** Press `Shift + Enter`

---

## 📊 What You Should See

After running, you should see:

```
📊 Model Architecture:
Model: "sequential"
_________________________________________________________________
 Layer (type)                Output Shape              Param #   
=================================================================
 batch_normalization (BatchN  (None, 30, 126)          504       
 ...
=================================================================
Total params: XXX,XXX
Trainable params: XXX,XXX
Non-trainable params: XXX
```

---

## 🎯 Step 5B: Define Training Callbacks

Callbacks help during training (early stopping, saving best model, etc.)

### Code to Run:

```python
# Define callbacks for training
callbacks = [
    keras.callbacks.EarlyStopping(
        monitor='val_loss',
        patience=10,
        restore_best_weights=True,
        verbose=1
    ),
    keras.callbacks.ModelCheckpoint(
        filepath=os.path.join(MODEL_DIR, 'best_model.h5'),
        monitor='val_accuracy',
        save_best_only=True,
        verbose=1
    ),
    keras.callbacks.ReduceLROnPlateau(
        monitor='val_loss',
        factor=0.5,
        patience=5,
        min_lr=1e-7,
        verbose=1
    ),
    keras.callbacks.CSVLogger(
        filename=os.path.join(OUTPUT_DIR, 'training_log.csv'),
        append=True
    )
]

print("✅ Callbacks defined successfully!")
print("   - Early stopping: Stops if no improvement for 10 epochs")
print("   - Model checkpoint: Saves best model based on validation accuracy")
print("   - Reduce LR: Reduces learning rate if stuck")
print("   - CSV logger: Saves training history")
```

**Run it:** Press `Shift + Enter`

---

## 🎯 Step 5C: Train the Model

This is the main training step. **This takes TIME!**

### Code to Run:

```python
# Train the model
print("🚀 Starting model training...")
print(f"   Training samples: {len(X_train)}")
print(f"   Validation samples: {len(X_val)}")
print(f"   Epochs: {EPOCHS}")
print(f"   Batch size: {BATCH_SIZE}")
print(f"   Learning rate: {LEARNING_RATE}")
print("\n⏱️  This may take 1-4 hours depending on GPU availability...\n")

history = model.fit(
    X_train, y_train,
    batch_size=BATCH_SIZE,
    epochs=EPOCHS,
    validation_data=(X_val, y_val),
    callbacks=callbacks,
    verbose=1
)

print("\n✅ Training completed!")
```

**Run it:** Press `Shift + Enter`

---

## ⏱️ What to Expect During Training

### Training Progress:
You'll see output like:
```
Epoch 1/50
29/29 [==============================] - 15s 500ms/step - loss: 4.2341 - accuracy: 0.0234 - val_loss: 4.1234 - val_accuracy: 0.0455

Epoch 2/50
29/29 [==============================] - 12s 400ms/step - loss: 3.8765 - accuracy: 0.0567 - val_loss: 3.9876 - val_accuracy: 0.0678
...
```

### What to Watch:
- **Loss**: Should decrease over time
- **Accuracy**: Should increase over time
- **Val Loss**: Should track training loss (if diverging = overfitting)
- **Val Accuracy**: Should increase

### Early Stopping:
- Will stop automatically if no improvement for 10 epochs
- Saves the best model automatically

---

## ⚠️ Important Notes

### 1. This Takes TIME
- **1-4 hours** depending on:
  - GPU availability
  - Number of epochs
  - Batch size
- **Keep Colab open!** Don't close the browser tab

### 2. Best Model is Saved Automatically
- Saved to: `/content/models/best_model.h5`
- Based on validation accuracy
- You don't need to save manually (but you can)

### 3. Training History is Saved
- Saved to: `/content/output/training_log.csv`
- Contains loss and accuracy for each epoch

---

## ✅ Success Indicators

**Good signs:**
- ✅ Loss decreasing steadily
- ✅ Accuracy increasing
- ✅ Validation metrics close to training metrics
- ✅ No "NaN" or "Inf" values
- ✅ Training completes without errors

**Warning signs:**
- ⚠️ Validation loss increasing while training loss decreases (overfitting)
- ⚠️ Accuracy stuck at same value (learning rate too low)
- ⚠️ Loss becomes NaN (learning rate too high or data issue)

---

## 📋 Quick Checklist

- [ ] Step 5A: Build model ✅
- [ ] Step 5B: Define callbacks ✅
- [ ] Step 5C: Train model ✅
- [ ] See training progress
- [ ] Loss decreasing, accuracy increasing
- [ ] Training completes successfully
- [ ] Ready for Step 6 (Evaluate Model)

---

## 🎯 After Training Completes

Next step: **Step 6: Evaluate the Model**

You'll:
1. Plot training history (loss and accuracy curves)
2. Evaluate on test set
3. Show confusion matrix
4. Save final model

---

## 💡 Pro Tips

1. **Monitor Training**: Watch validation accuracy - if it stops improving, training may be done
2. **Early Stopping**: Will stop automatically if no improvement
3. **Best Model**: Automatically saved based on validation accuracy
4. **GPU**: Make sure GPU is enabled for faster training (Runtime → Change runtime type → GPU)

---

**This is the longest step! Be patient and let it train! 🚀**



