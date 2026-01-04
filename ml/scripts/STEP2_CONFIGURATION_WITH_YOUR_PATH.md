# ⚙️ Step 2: Configuration - With Your Folder Path

## Your Folder Structure
Based on your Google Drive:
- Path: `drive/MyDrive/MathsSigns_Project/raw_videos/`
- Contains folders: 1, 10, 100, 103, 105, 109, 11, 110, 12, 124, 13, 130, etc.

---

## Step 2A: Configuration Code

```python
# Configuration
DATA_DIR = '/content/data_raw'  # This is where we'll copy your videos
OUTPUT_DIR = '/content/output'
MODEL_DIR = '/content/models'

# Create directories
os.makedirs(OUTPUT_DIR, exist_ok=True)
os.makedirs(MODEL_DIR, exist_ok=True)

# Model parameters
SEQUENCE_LENGTH = 30  # Number of frames to use for each video
IMG_HEIGHT = 224
IMG_WIDTH = 224
NUM_CLASSES = None  # Will be determined from data
EPOCHS = 50
BATCH_SIZE = 32
LEARNING_RATE = 0.001

# MediaPipe settings
mp_hands = mp.solutions.hands
mp_pose = mp.solutions.pose
mp_drawing = mp.solutions.drawing_utils
```

---

## Step 2B: Mount Google Drive and Copy Your Data

After running the configuration, run this code:

```python
# Step 1: Mount Google Drive
from google.colab import drive
drive.mount('/content/drive')

# Step 2: Copy your videos from Google Drive to Colab
# Your path: /content/drive/MyDrive/MathsSigns_Project/raw_videos
DRIVE_DATA_PATH = '/content/drive/MyDrive/MathsSigns_Project/raw_videos'

# Create data directory
!mkdir -p {DATA_DIR}

# Copy all folders from raw_videos to data_raw
!cp -r '{DRIVE_DATA_PATH}'/* {DATA_DIR}/

# Verify the copy worked
print("✅ Data copied successfully!")
print(f"\nFolders in {DATA_DIR}:")
!ls {DATA_DIR}
```

---

## 🎯 Complete Step-by-Step Instructions

### Step 1: Run Configuration
1. Paste the **Step 2A** code above
2. Run it (Shift + Enter)
3. Should complete without errors

### Step 2: Mount Google Drive
1. Paste the **Step 2B** code above
2. Run it (Shift + Enter)
3. **You'll see a link** - click it
4. **Authorize access** - select your Google account
5. **Copy the authorization code**
6. **Paste it** in the box that appears
7. Press Enter

### Step 3: Verify Data Copied
After mounting, the code will automatically:
- Copy your videos from Google Drive
- Show you the folders that were copied
- You should see: 1, 10, 100, 103, 105, etc.

---

## ✅ What You Should See

After Step 2B completes, you should see:
```
✅ Data copied successfully!

Folders in /content/data_raw:
1    10    100    103    105    109    11    110    12    124    13    130
```

---

## 🆘 Troubleshooting

### Error: "No such file or directory"
**Fix:** Make sure the path is correct:
```python
DRIVE_DATA_PATH = '/content/drive/MyDrive/MathsSigns_Project/raw_videos'
```

### Error: "Permission denied"
**Fix:** Make sure you authorized Google Drive access

### No folders copied
**Fix:** Check that `raw_videos` folder exists in Google Drive at that exact path

---

## 📋 Quick Checklist

- [ ] Ran Step 2A (Configuration)
- [ ] Ran Step 2B (Mount Drive)
- [ ] Clicked authorization link
- [ ] Pasted authorization code
- [ ] Saw "Data copied successfully!"
- [ ] Saw folder list (1, 10, 100, etc.)
- [ ] Ready for Step 3 (Extract Features)

---

**After this works, you're ready to extract features from your videos! 🎬**



