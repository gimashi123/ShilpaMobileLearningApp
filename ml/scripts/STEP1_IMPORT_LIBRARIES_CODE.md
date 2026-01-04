# 📚 Step 1: Import Libraries - Code to Run

## Copy and Paste This Code

Here's the exact code you need to run for Step 1:

```python
# Import libraries
import os
import cv2
import numpy as np
import mediapipe as mp
import tensorflow as tf
from tensorflow import keras
from tensorflow.keras import layers
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix
import matplotlib.pyplot as plt
import seaborn as sns
from tqdm import tqdm
import pickle
from pathlib import Path
import warnings
warnings.filterwarnings('ignore')

print(f"TensorFlow version: {tf.__version__}")
print(f"MediaPipe version: {mp.__version__}")
```

---

## 🎯 How to Use This Code

### Step 1: Find or Create a Cell
- If there's already an "Import libraries" cell, click inside it
- If not, create a new cell (click the "+ Code" button)

### Step 2: Paste the Code
- Select all the code above
- Copy it (Ctrl+C or Cmd+C)
- Paste it into the cell (Ctrl+V or Cmd+V)

### Step 3: Run the Cell
- Press `Shift + Enter`
- Or click the ▶️ Play button

### Step 4: Check the Output
You should see something like:
```
TensorFlow version: 2.19.0
MediaPipe version: 0.10.21
```

---

## ✅ Success Indicators

**Good signs:**
- ✅ No red error messages
- ✅ You see TensorFlow version number
- ✅ You see MediaPipe version number
- ✅ Cell shows `[1]` or a number (means it ran)

**Bad signs:**
- ❌ Red error messages
- ❌ "ModuleNotFoundError"
- ❌ Import errors

---

## 🆘 If You See Errors

### Error: "No module named 'tensorflow'"
**Fix:** Go back and run the installation cell again

### Error: "No module named 'mediapipe'"
**Fix:** Go back and run the installation cell again

### Error: "No module named 'cv2'"
**Fix:** Run this:
```python
!pip install opencv-python
```

---

## 📝 Quick Checklist

- [ ] Found or created a code cell
- [ ] Pasted the import code
- [ ] Ran the cell (Shift + Enter)
- [ ] Saw TensorFlow version
- [ ] Saw MediaPipe version
- [ ] No errors
- [ ] Ready for Step 2 (Configuration)

---

**After this works, move to Step 2: Configuration! 🚀**



