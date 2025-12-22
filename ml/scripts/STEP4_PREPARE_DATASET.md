# 📊 Step 4: Prepare Dataset for Training - Complete Guide

## ✅ What You've Completed
- [x] Installed packages
- [x] Imported libraries
- [x] Configuration
- [x] Copied data from Google Drive
- [x] Extracted features (1312 samples, hands-only) ✅

---

## 🎯 Step 4: Prepare Dataset for Training

This step will:
- Split your data into **training**, **validation**, and **test** sets
- Encode labels (convert numbers to 0, 1, 2, ...)
- Convert labels to categorical format (for multi-class classification)
- Save the label encoder (so you can decode predictions later)

---

## 📝 Code to Run

**Copy and paste this code into a new cell:**

```python
# Prepare dataset for training
(X_train, y_train), (X_val, y_val), (X_test, y_test), label_encoder, NUM_CLASSES = prepare_dataset(X, y)

# Save label encoder (important for later predictions!)
with open(os.path.join(MODEL_DIR, 'label_encoder.pkl'), 'wb') as f:
    pickle.dump(label_encoder, f)

print("\n✅ Dataset prepared successfully!")
print(f"💾 Label encoder saved to {os.path.join(MODEL_DIR, 'label_encoder.pkl')}")
```

**Run it:** Press `Shift + Enter`

---

## 📊 What You Should See

After running, you should see:

```
Training samples: 945
Validation samples: 131
Test samples: 236
Number of classes: 83
Feature shape: (945, 30, 126)

✅ Dataset prepared successfully!
💾 Label encoder saved to /content/models/label_encoder.pkl
```

**Note:** The exact numbers might be slightly different, but should be similar.

---

## 🔍 What This Does

### 1. Data Splitting
- **Training (70%)**: ~945 samples - Used to train the model
- **Validation (10%)**: ~131 samples - Used to tune hyperparameters
- **Test (20%)**: ~236 samples - Used to evaluate final performance

### 2. Label Encoding
- Converts your numbers (1, 2, 3, ..., 200) to indices (0, 1, 2, ..., 82)
- Example: Number 1 → 0, Number 2 → 1, etc.

### 3. Categorical Conversion
- Converts labels to one-hot encoding
- Example: Label 0 → [1, 0, 0, ..., 0] (83 classes)

### 4. Label Encoder Saving
- Saves the mapping so you can decode predictions later
- Example: Prediction 0 → Number 1

---

## ⚠️ Important Notes

### If You Get an Error: "name 'prepare_dataset' is not defined"

You need to define the function first. Add this code **before** the prepare dataset code:

```python
def prepare_dataset(X, y, test_size=0.2, val_size=0.1, random_state=42):
    """
    Prepare dataset for training with train/validation/test splits.
    """
    # Encode labels
    label_encoder = LabelEncoder()
    y_encoded = label_encoder.fit_transform(y)
    
    # First split: train+val and test
    X_temp, X_test, y_temp, y_test = train_test_split(
        X, y_encoded, test_size=test_size, random_state=random_state, stratify=y_encoded
    )
    
    # Second split: train and val
    val_size_adjusted = val_size / (1 - test_size)
    X_train, X_val, y_train, y_val = train_test_split(
        X_temp, y_temp, test_size=val_size_adjusted, random_state=random_state, stratify=y_temp
    )
    
    # Convert to categorical for multi-class classification
    num_classes = len(np.unique(y_encoded))
    y_train_cat = keras.utils.to_categorical(y_train, num_classes)
    y_val_cat = keras.utils.to_categorical(y_val, num_classes)
    y_test_cat = keras.utils.to_categorical(y_test, num_classes)
    
    print(f"Training samples: {len(X_train)}")
    print(f"Validation samples: {len(X_val)}")
    print(f"Test samples: {len(X_test)}")
    print(f"Number of classes: {num_classes}")
    print(f"Feature shape: {X_train.shape}")
    
    return (X_train, y_train_cat), (X_val, y_val_cat), (X_test, y_test_cat), label_encoder, num_classes
```

---

## ✅ Success Indicators

**Good signs:**
- ✅ See "Training samples: XXX"
- ✅ See "Validation samples: XXX"
- ✅ See "Test samples: XXX"
- ✅ See "Number of classes: 83"
- ✅ See "Dataset prepared successfully!"
- ✅ No errors

**Bad signs:**
- ❌ "NameError: name 'prepare_dataset' is not defined" → Add function definition first
- ❌ "NameError: name 'X' is not defined" → Make sure you ran feature extraction
- ❌ "NameError: name 'y' is not defined" → Make sure you ran feature extraction

---

## 📋 Quick Checklist

- [ ] Ran feature extraction (Step 3) ✅
- [ ] Have X and y variables defined
- [ ] Pasted prepare_dataset function (if needed)
- [ ] Pasted prepare dataset code
- [ ] Ran the cell (Shift + Enter)
- [ ] Saw training/validation/test sample counts
- [ ] Saw "Dataset prepared successfully!"
- [ ] Ready for Step 5 (Build Model)

---

## 🎯 After This Completes

Next step: **Step 5: Build and Train the Model**

You'll:
1. Build the LSTM model architecture
2. Train the model
3. Evaluate performance

---

## 💡 Pro Tips

1. **Stratified Split**: The code uses `stratify=y_encoded` to ensure each split has similar class distribution
2. **Random State**: Uses `random_state=42` for reproducibility
3. **Label Encoder**: Save it! You'll need it to decode predictions later

---

**After this works, you're ready to build and train your model! 🚀**



