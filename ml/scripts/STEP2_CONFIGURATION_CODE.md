# ⚙️ Step 2: Configuration - Code to Run

## Copy and Paste This Code

Here's the exact code for Step 2: Configuration:

```python
# Configuration
DATA_DIR = '/content/data_raw'  # Update this path to your data directory
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

## 🎯 How to Use This Code

### Step 1: Find or Create a Cell
- Find the cell that says "Step 2: Configuration"
- Or create a new cell (click "+ Code")

### Step 2: Paste the Code
- Copy all the code above
- Paste it into the cell

### Step 3: Run the Cell
- Press `Shift + Enter`
- Or click the ▶️ Play button

### Step 4: Check the Output
- You should see **NO errors**
- The cell should just run and complete
- Directories will be created automatically

---

## ✅ Success Indicators

**Good signs:**
- ✅ Cell runs without errors
- ✅ No red error messages
- ✅ Cell shows `[1]` or a number (means it ran)
- ✅ Directories are created (you won't see output, but they're created)

**Bad signs:**
- ❌ Red error messages
- ❌ "NameError" (means Step 1 didn't run properly)

---

## 📝 What This Code Does

1. **Sets up folder paths:**
   - `DATA_DIR` - Where your video files will be
   - `OUTPUT_DIR` - Where processed data is saved
   - `MODEL_DIR` - Where trained model is saved

2. **Creates directories:**
   - Creates `/content/output` folder
   - Creates `/content/models` folder

3. **Sets training parameters:**
   - `SEQUENCE_LENGTH = 30` - Uses 30 frames per video
   - `EPOCHS = 50` - Trains for 50 iterations
   - `BATCH_SIZE = 32` - Processes 32 samples at a time
   - `LEARNING_RATE = 0.001` - How fast the model learns

4. **Sets up MediaPipe:**
   - Prepares hand and pose detection

---

## 🔧 Optional: Adjust Parameters

You can change these if needed (but defaults are fine):

```python
EPOCHS = 50        # More = longer training, but might overfit
BATCH_SIZE = 32    # Smaller = slower but uses less memory
SEQUENCE_LENGTH = 30  # More frames = more detail but slower
```

---

## 🆘 If You See Errors

### Error: "NameError: name 'os' is not defined"
**Fix:** Go back and run Step 1 (Import libraries) first

### Error: "NameError: name 'mp' is not defined"
**Fix:** Go back and run Step 1 (Import libraries) first

---

## 📋 Quick Checklist

- [ ] Found or created a code cell
- [ ] Pasted the configuration code
- [ ] Ran the cell (Shift + Enter)
- [ ] No errors
- [ ] Cell completed successfully
- [ ] Ready for Step 3 (Upload Video Data)

---

## 🚀 After This Step

Next you'll need to:
1. **Upload your video data** (Step 3)
2. Make sure videos are organized in folders by number
3. Then extract features (Step 4)

---

**After this works, you're ready to upload your video data! 🎬**



