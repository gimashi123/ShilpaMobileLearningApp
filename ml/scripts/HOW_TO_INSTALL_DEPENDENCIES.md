# 📦 How to Install Dependencies in Colab - Step by Step

## Step 4.1: Install Dependencies

### What You'll Do
Install all the required Python packages needed for the sign language training.

---

## 🎯 Visual Guide

### Step 1: Find the Installation Cell

In your Colab notebook, look for this cell:

```python
# Install required packages
!pip install -q mediapipe opencv-python tensorflow numpy scikit-learn matplotlib seaborn tqdm
```

**Location:** It should be in "Step 1: Setup and Install Dependencies" section, right after the "Check if Running in Colab" cell.

---

### Step 2: Select the Cell

1. **Click anywhere inside the cell** - You'll see a blue border appear around it
2. The cell is now selected and ready to run

---

### Step 3: Run the Cell

You have **3 ways** to run it:

#### Option A: Keyboard Shortcut (Fastest) ⚡
- Press **`Shift + Enter`** on your keyboard
- The cell will execute and automatically move to the next cell

#### Option B: Play Button
- Click the **▶️ Play button** on the left side of the cell
- The cell will execute

#### Option C: Menu
- Click **Runtime** → **Run selection** (or **Run focused cell**)

---

### Step 4: Wait for Installation

After running, you'll see:

1. **A spinning icon** ⏳ - This means the cell is running
2. **Output appearing below the cell** - You'll see installation progress

**What you'll see:**
```
Collecting mediapipe
  Downloading mediapipe-0.10.x...
Collecting opencv-python
  Downloading opencv-python-4.x.x...
...
Successfully installed mediapipe-0.10.x opencv-python-4.x.x tensorflow-2.x.x numpy-1.x.x scikit-learn-1.x.x matplotlib-3.x.x seaborn-0.x.x tqdm-4.x.x
```

**Time:** This takes about **1-2 minutes** depending on your internet speed.

---

### Step 5: Verify Installation

After installation completes:

1. **Look for:** "Successfully installed..." message
2. **No red error messages** should appear
3. **The cell number** will change from `[ ]` to `[1]` (or another number)

---

## ✅ Success Indicators

You'll know it worked when you see:

- ✅ Cell shows `[1]` (or a number) instead of `[ ]`
- ✅ "Successfully installed..." message appears
- ✅ No red error text
- ✅ Next cell is automatically selected (if you used Shift+Enter)

---

## ❌ Troubleshooting

### Problem: "No module named 'pip'"
**Solution:** This shouldn't happen in Colab, but if it does:
```python
!python -m ensurepip --upgrade
!python -m pip install --upgrade pip
```

### Problem: Installation is very slow
**Solution:** 
- This is normal for the first time
- Colab downloads packages from the internet
- Wait patiently - it will complete

### Problem: "ERROR: Could not install packages"
**Solution:**
- Try running the cell again
- Sometimes network issues cause temporary failures
- If it persists, restart runtime: **Runtime → Restart runtime**, then try again

### Problem: Cell keeps running forever
**Solution:**
- Check your internet connection
- Stop the cell: Click the **⏹️ Stop button** (square icon)
- Restart runtime: **Runtime → Restart runtime**
- Run the cell again

---

## 🔄 What Happens Next?

After successful installation:

1. **Move to the next cell** - "Import libraries" cell
2. **Run that cell** to verify everything is installed correctly
3. You should see TensorFlow and MediaPipe version numbers printed

---

## 💡 Pro Tips

1. **Run cells in order** - Don't skip ahead
2. **Wait for completion** - Don't run multiple cells at once
3. **Check for errors** - Red text means something went wrong
4. **Save your progress** - Colab auto-saves, but you can also: **File → Save**

---

## 📝 Quick Checklist

- [ ] Found the "Install required packages" cell
- [ ] Selected the cell (blue border visible)
- [ ] Ran the cell (Shift + Enter or Play button)
- [ ] Waited for installation to complete (~1-2 min)
- [ ] Saw "Successfully installed..." message
- [ ] No red error messages
- [ ] Cell number changed from `[ ]` to `[1]`
- [ ] Ready to move to next step (Import libraries)

---

## 🎬 Example Walkthrough

```
1. You see this cell:
   ┌─────────────────────────────────────────┐
   │ # Install required packages            │
   │ !pip install -q mediapipe opencv...    │
   └─────────────────────────────────────────┘
   [ ]  ← Empty brackets mean not run yet

2. Click inside the cell (it gets blue border)

3. Press Shift + Enter

4. You see:
   ┌─────────────────────────────────────────┐
   │ # Install required packages            │
   │ !pip install -q mediapipe opencv...    │
   └─────────────────────────────────────────┘
   [1]  ← Number means it ran
   
   Collecting mediapipe...
   Successfully installed...

5. ✅ Done! Move to next cell.
```

---

**That's it! You've successfully installed all dependencies. 🎉**

Now you can proceed to the next step: **Import libraries**.



