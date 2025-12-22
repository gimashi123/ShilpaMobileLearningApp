# ⚙️ Step 2: Complete Guide - Your Data is Already in Google Drive

## ✅ What You Have
- Data already uploaded to Google Drive
- Path: `drive/MyDrive/MathsSigns_Project/raw_videos/`
- Folders: 1, 10, 100, 103, 105, 109, 11, 110, 12, 124, 13, 130, etc.
- Video files: .MOV files in each folder

---

## 🎯 Step 2A: Configuration Code

**Copy and paste this code into a NEW cell:**

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

print("✅ Configuration completed!")
```

**Run it:** Press `Shift + Enter`

**What you should see:**
- ✅ Configuration completed!
- No errors

---

## 🎯 Step 2B: Mount Google Drive (If Not Already Mounted)

**Check first:** Look at your file explorer. If you can see the `drive` folder, it's already mounted! Skip to Step 2C.

**If you DON'T see the drive folder, run this:**

```python
# Mount Google Drive
from google.colab import drive
drive.mount('/content/drive')
```

**What happens:**
1. You'll see a link - **click it**
2. Select your Google account
3. **Copy the authorization code**
4. **Paste it** in the box
5. Press Enter

**You should see:**
```
Mounted at /content/drive
```

---

## 🎯 Step 2C: Copy Your Data from Google Drive

**Copy and paste this code into a NEW cell:**

```python
# Copy your videos from Google Drive to Colab
# Your path: /content/drive/MyDrive/MathsSigns_Project/raw_videos
DRIVE_DATA_PATH = '/content/drive/MyDrive/MathsSigns_Project/raw_videos'

# Create data directory
!mkdir -p {DATA_DIR}

# Copy all folders from raw_videos to data_raw
print("📁 Copying videos from Google Drive...")
!cp -r '{DRIVE_DATA_PATH}'/* {DATA_DIR}/

# Verify the copy worked
print("\n✅ Data copied successfully!")
print(f"\n📂 Folders in {DATA_DIR}:")
!ls {DATA_DIR} | head -20  # Show first 20 folders
print(f"\n📊 Total folders: {len([f for f in os.listdir(DATA_DIR) if os.path.isdir(os.path.join(DATA_DIR, f))])}")
```

**Run it:** Press `Shift + Enter`

**What you should see:**
```
📁 Copying videos from Google Drive...
✅ Data copied successfully!

📂 Folders in /content/data_raw:
1    10    100    103    105    109    11    110    12    124    13    130

📊 Total folders: XX
```

---

## ✅ Complete Checklist

- [ ] Step 2A: Run Configuration code
- [ ] Step 2B: Check if Drive is mounted (or mount it)
- [ ] Step 2C: Copy data from Google Drive
- [ ] See "Data copied successfully!"
- [ ] See your folder list (1, 10, 100, etc.)
- [ ] Ready for Step 3 (Extract Features)

---

## 🆘 Troubleshooting

### Error: "No such file or directory"
**Check:** Make sure the path is exactly:
```python
DRIVE_DATA_PATH = '/content/drive/MyDrive/MathsSigns_Project/raw_videos'
```

### Error: "Permission denied"
**Fix:** Make sure Google Drive is mounted. Run Step 2B first.

### No folders copied
**Fix:** 
1. Check the file explorer - can you see `drive/MyDrive/MathsSigns_Project/raw_videos`?
2. If yes, the path is correct
3. If no, check the exact folder name in Google Drive

### Drive already mounted
**Good!** Just skip Step 2B and go directly to Step 2C.

---

## 🎯 After This Works

Next step: **Step 3: Extract Features from Videos**

You'll run:
```python
X, y = process_all_videos(DATA_DIR)
```

This will process all your .MOV files and extract landmarks.

---

**You're doing great! Follow these steps one by one! 🚀**



