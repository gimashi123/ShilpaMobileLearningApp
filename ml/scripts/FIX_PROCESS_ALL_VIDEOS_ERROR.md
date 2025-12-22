# 🔧 Fix: NameError - process_all_videos is not defined

## ❌ The Problem

You're getting: `NameError: name 'process_all_videos' is not defined`

**Why?** The function `process_all_videos` hasn't been defined yet. You need to run the cells that define the functions first!

---

## ✅ The Fix - Step by Step

### Step 1: Find the Function Definition Cells

In your notebook, look for these cells **BEFORE** the "Process all videos" cell:

1. **Cell with:** `def extract_landmarks_from_video(...)`
2. **Cell with:** `def process_all_videos(...)`

These are usually in the "Step 4: Extract Features from Videos" section.

---

### Step 2: Run the Function Definition Cells First

**You need to run these cells IN ORDER:**

#### Cell 1: Extract Landmarks Function
```python
def extract_landmarks_from_video(video_path, max_frames=SEQUENCE_LENGTH):
    """
    Extract hand and pose landmarks from a video file.
    ...
    """
    # (long function code here)
```

**Run this cell first!** (Shift + Enter)

#### Cell 2: Process All Videos Function
```python
def process_all_videos(data_dir, output_file='landmarks_data.pkl'):
    """
    Process all videos in the data directory and extract landmarks.
    ...
    """
    # (long function code here)
```

**Run this cell second!** (Shift + Enter)

#### Cell 3: Now Run Your Processing Code
```python
# Process all videos (this may take a while)
X, y = process_all_videos(DATA_DIR)
```

**Run this cell third!** (Shift + Enter)

---

## 🎯 Quick Fix - All Code in One Cell

If you can't find the function cells, paste this **COMPLETE code** into a new cell:

```python
def extract_landmarks_from_video(video_path, max_frames=SEQUENCE_LENGTH):
    """
    Extract hand and pose landmarks from a video file.
    """
    cap = cv2.VideoCapture(video_path)
    
    # Initialize MediaPipe
    hands = mp_hands.Hands(
        static_image_mode=False,
        max_num_hands=2,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    )
    
    pose = mp_pose.Pose(
        static_image_mode=False,
        min_detection_confidence=0.5,
        min_tracking_confidence=0.5
    )
    
    landmarks_list = []
    frame_count = 0
    
    while cap.isOpened() and frame_count < max_frames:
        ret, frame = cap.read()
        if not ret:
            break
        
        # Convert BGR to RGB
        frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        
        # Process with MediaPipe
        hand_results = hands.process(frame_rgb)
        pose_results = pose.process(frame_rgb)
        
        # Extract landmarks
        frame_landmarks = []
        
        # Hand landmarks (21 points per hand, 2 hands max = 42 points)
        if hand_results.multi_hand_landmarks:
            for hand_landmarks in hand_results.multi_hand_landmarks:
                for landmark in hand_landmarks.landmark:
                    frame_landmarks.extend([landmark.x, landmark.y, landmark.z])
            # Pad if only one hand detected
            if len(hand_results.multi_hand_landmarks) == 1:
                frame_landmarks.extend([0.0] * 63)  # 21 points * 3 coords
        else:
            # No hands detected, pad with zeros
            frame_landmarks.extend([0.0] * 126)  # 2 hands * 21 points * 3 coords
        
        # Pose landmarks (33 points)
        if pose_results.pose_landmarks:
            for landmark in pose_results.pose_landmarks.landmark:
                frame_landmarks.extend([landmark.x, landmark.y, landmark.z, landmark.visibility])
        else:
            # No pose detected, pad with zeros
            frame_landmarks.extend([0.0] * 132)  # 33 points * 4 coords
        
        landmarks_list.append(frame_landmarks)
        frame_count += 1
    
    cap.release()
    hands.close()
    pose.close()
    
    # Pad or truncate to max_frames
    if len(landmarks_list) < max_frames:
        # Pad with last frame
        last_frame = landmarks_list[-1] if landmarks_list else [0.0] * 258
        while len(landmarks_list) < max_frames:
            landmarks_list.append(last_frame)
    elif len(landmarks_list) > max_frames:
        # Truncate
        landmarks_list = landmarks_list[:max_frames]
    
    return np.array(landmarks_list, dtype=np.float32)


def process_all_videos(data_dir, output_file='landmarks_data.pkl'):
    """
    Process all videos in the data directory and extract landmarks.
    """
    X = []  # Features
    y = []  # Labels
    
    # Supported video formats
    video_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv']
    
    # Get all number folders
    data_path = Path(data_dir)
    number_folders = sorted([f for f in data_path.iterdir() if f.is_dir()])
    
    print(f"Found {len(number_folders)} number folders")
    
    for number_folder in tqdm(number_folders, desc="Processing folders"):
        # Extract number from folder name
        folder_name = number_folder.name
        try:
            number = int(''.join(filter(str.isdigit, folder_name)))
        except:
            print(f"Warning: Could not extract number from folder {folder_name}, skipping...")
            continue
        
        # Get all video files in this folder
        video_files = [f for f in number_folder.iterdir() 
                      if f.suffix.lower() in video_extensions]
        
        print(f"\nProcessing {len(video_files)} videos for number {number}")
        
        for video_file in tqdm(video_files, desc=f"Number {number}", leave=False):
            try:
                landmarks = extract_landmarks_from_video(str(video_file))
                X.append(landmarks)
                y.append(number)
            except Exception as e:
                print(f"\nError processing {video_file}: {str(e)}")
                continue
    
    X = np.array(X)
    y = np.array(y)
    
    print(f"\nTotal samples: {len(X)}")
    print(f"Feature shape: {X.shape}")
    print(f"Unique labels: {len(np.unique(y))}")
    print(f"Labels: {sorted(np.unique(y))}")
    
    # Save processed data
    with open(os.path.join(OUTPUT_DIR, output_file), 'wb') as f:
        pickle.dump({'X': X, 'y': y}, f)
    
    print(f"\nSaved processed data to {os.path.join(OUTPUT_DIR, output_file)}")
    
    return X, y


# Now process all videos
print("🚀 Starting video processing...")
X, y = process_all_videos(DATA_DIR)
```

**Run this complete cell!** It includes both function definitions AND the processing call.

---

## ✅ What You Should See

After running the complete code:

```
🚀 Starting video processing...
Found 83 number folders
Processing folders:   0%|          | 0/83 [00:00<?, ?it/s]
Processing 11 videos for number 1
...
```

Then progress bars will appear as it processes.

---

## 📋 Quick Checklist

- [ ] Found the function definition cells OR
- [ ] Pasted the complete code (both functions + processing)
- [ ] Ran the cell (Shift + Enter)
- [ ] See "Found 83 number folders"
- [ ] See progress bars
- [ ] No NameError
- [ ] Processing started successfully

---

## 🆘 Still Having Issues?

### Error: "NameError: name 'SEQUENCE_LENGTH' is not defined"
**Fix:** Make sure you ran the Configuration cell (Step 2A)

### Error: "NameError: name 'mp_hands' is not defined"
**Fix:** Make sure you ran the Configuration cell (Step 2A)

### Error: "ModuleNotFoundError"
**Fix:** Run the Import Libraries cell again

---

**After this works, the processing will start! Let it run for 1-4 hours! 🚀**



