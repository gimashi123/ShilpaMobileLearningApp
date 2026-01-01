# 📊 Step 6: Evaluate the Model - Complete Guide

## ✅ What You've Completed
- [x] Built model ✅
- [x] Defined callbacks ✅
- [x] Trained model (50 epochs, best val accuracy: 8.33%) ✅

---

## 🎯 Step 6: Evaluate the Model

This step will:
1. Plot training history (loss and accuracy curves)
2. Evaluate on test set (final accuracy)
3. Show confusion matrix
4. Save final model

---

## 📝 Step 6A: Plot Training History

**Copy and paste this code:**

```python
def plot_training_history(history):
    """
    Plot training history (loss and accuracy curves).
    """
    fig, axes = plt.subplots(1, 2, figsize=(15, 5))
    
    # Plot loss
    axes[0].plot(history.history['loss'], label='Training Loss')
    axes[0].plot(history.history['val_loss'], label='Validation Loss')
    axes[0].set_title('Model Loss')
    axes[0].set_xlabel('Epoch')
    axes[0].set_ylabel('Loss')
    axes[0].legend()
    axes[0].grid(True)
    
    # Plot accuracy
    axes[1].plot(history.history['accuracy'], label='Training Accuracy')
    axes[1].plot(history.history['val_accuracy'], label='Validation Accuracy')
    axes[1].set_title('Model Accuracy')
    axes[1].set_xlabel('Epoch')
    axes[1].set_ylabel('Accuracy')
    axes[1].legend()
    axes[1].grid(True)
    
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'training_history.png'), dpi=300, bbox_inches='tight')
    plt.show()

# Plot training history
print("📊 Plotting training history...")
plot_training_history(history)
```

**Run it:** Press `Shift + Enter`

**What you'll see:**
- Two plots showing loss and accuracy over epochs
- Saved to `/content/output/training_history.png`

---

## 📝 Step 6B: Evaluate on Test Set

**Copy and paste this code:**

```python
def evaluate_model(model, X_test, y_test, label_encoder):
    """
    Evaluate the model on test set and print detailed metrics.
    """
    # Predictions
    y_pred_proba = model.predict(X_test, verbose=0)
    y_pred = np.argmax(y_pred_proba, axis=1)
    y_true = np.argmax(y_test, axis=1)
    
    # Decode labels
    y_true_decoded = label_encoder.inverse_transform(y_true)
    y_pred_decoded = label_encoder.inverse_transform(y_pred)
    
    # Calculate accuracy
    test_loss, test_accuracy, test_top_k = model.evaluate(X_test, y_test, verbose=0)
    
    print(f"\n📊 Test Set Evaluation:")
    print(f"   Test Loss: {test_loss:.4f}")
    print(f"   Test Accuracy: {test_accuracy:.4f} ({test_accuracy*100:.2f}%)")
    print(f"   Test Top-K Accuracy: {test_top_k:.4f} ({test_top_k*100:.2f}%)")
    
    # Classification report
    print("\n📋 Classification Report:")
    print(classification_report(y_true_decoded, y_pred_decoded))
    
    # Confusion matrix
    cm = confusion_matrix(y_true_decoded, y_pred_decoded)
    
    plt.figure(figsize=(15, 12))
    sns.heatmap(cm, annot=False, fmt='d', cmap='Blues', 
                xticklabels=sorted(label_encoder.classes_)[::5],  # Show every 5th label
                yticklabels=sorted(label_encoder.classes_)[::5])
    plt.title('Confusion Matrix (Test Set)')
    plt.ylabel('True Label')
    plt.xlabel('Predicted Label')
    plt.tight_layout()
    plt.savefig(os.path.join(OUTPUT_DIR, 'confusion_matrix.png'), dpi=300, bbox_inches='tight')
    plt.show()
    
    return test_accuracy, y_pred_decoded, y_true_decoded

# Evaluate model on test set
print("🔍 Evaluating model on test set...")
test_accuracy, y_pred, y_true = evaluate_model(model, X_test, y_test, label_encoder)
```

**Run it:** Press `Shift + Enter`

**What you'll see:**
- Test accuracy (final performance)
- Classification report (precision, recall, F1-score per class)
- Confusion matrix (which numbers are confused with which)

---

## 📝 Step 6C: Save Final Model

**Copy and paste this code:**

```python
# Save the final model
model.save(os.path.join(MODEL_DIR, 'sign_language_numbers_model.h5'))
model.save(os.path.join(MODEL_DIR, 'sign_language_numbers_model'))  # SavedModel format

# Save model summary
with open(os.path.join(MODEL_DIR, 'model_summary.txt'), 'w') as f:
    model.summary(print_fn=lambda x: f.write(x + '\n'))

print(f"\n✅ Model saved to {MODEL_DIR}")
print(f"   - sign_language_numbers_model.h5")
print(f"   - sign_language_numbers_model/ (SavedModel format)")
print(f"   - model_summary.txt")
print(f"   - best_model.h5 (already saved during training)")
```

**Run it:** Press `Shift + Enter`

---

## 📊 Understanding Your Results

### Current Performance:
- **Validation Accuracy:** 8.33% (best at epoch 47)
- **Training Accuracy:** ~5-6%
- **With 83 classes:** Random guessing = 1.2%

### What This Means:
- ✅ **Better than random** (8.33% vs 1.2%)
- ⚠️ **Still low** - Model is learning but needs improvement

### Why Accuracy Might Be Low:
1. **Limited data per class** - Only ~15-16 videos per number on average
2. **83 classes** - Very challenging with limited data
3. **Class imbalance** - Some numbers might have more/less videos
4. **Model complexity** - Might need tuning

---

## 💡 How to Check Accuracy

### 1. Test Accuracy (Final Performance)
```python
test_accuracy, y_pred, y_true = evaluate_model(model, X_test, y_test, label_encoder)
print(f"Test Accuracy: {test_accuracy:.4f} ({test_accuracy*100:.2f}%)")
```

### 2. Validation Accuracy (During Training)
- Already shown in training output
- Best: 8.33% at epoch 47

### 3. Training Accuracy (During Training)
- Already shown in training output
- Final: ~5-6%

### 4. Top-K Accuracy
- Shows if correct answer is in top-K predictions
- Better metric for multi-class problems

---

## 🎯 Next Steps After Evaluation

### Option 1: Use Current Model
- If accuracy is acceptable for your use case
- Download and use the model

### Option 2: Improve Model
- Collect more training data
- Data augmentation
- Model architecture tuning
- Hyperparameter tuning

### Option 3: Download Model
- Step 7: Download the model files

---

## 📋 Quick Checklist

- [ ] Step 6A: Plot training history
- [ ] Step 6B: Evaluate on test set
- [ ] Step 6C: Save final model
- [ ] See test accuracy
- [ ] See confusion matrix
- [ ] Model files saved
- [ ] Ready for Step 7 (Download Model)

---

## 🆘 If Accuracy is Low

**Don't worry!** Here are ways to improve:

1. **More Data:**
   - Collect more videos per number
   - Aim for 20-30+ videos per number

2. **Data Augmentation:**
   - Flip videos horizontally
   - Add noise
   - Speed up/slow down

3. **Model Tuning:**
   - Adjust learning rate
   - Change batch size
   - Modify architecture

4. **Class Balancing:**
   - Ensure similar number of videos per class

---

**Run Step 6 to see your final accuracy! 📊**



