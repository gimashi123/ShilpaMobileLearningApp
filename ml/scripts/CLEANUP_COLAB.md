# 🧹 Cleanup Colab - Delete Everything Except Dataset

## 🎯 What This Does

Deletes all processed files, models, and outputs, but **keeps your original dataset**.

---

## 📝 Cleanup Code for Colab

**Copy and paste this into a Colab cell:**

```python
import os
import shutil

print("🧹 Cleaning up Colab environment...")
print("   (Keeping only your original dataset)\n")

# Directories to clean
directories_to_clean = [
    '/content/output',      # Processed data, logs, plots
    '/content/models',      # Trained models
    '/content/sample_data', # Colab sample data (optional)
]

# Files to clean
files_to_clean = [
    '/content/sign_language_model.zip',
    '/content/model.zip',
    '/content/*.pkl',
    '/content/*.h5',
    '/content/*.csv',
    '/content/*.png',
    '/content/*.txt',
]

# Clean directories
for dir_path in directories_to_clean:
    if os.path.exists(dir_path):
        print(f"🗑️  Deleting: {dir_path}")
        shutil.rmtree(dir_path)
        print(f"   ✅ Deleted")
    else:
        print(f"⏭️  Skipping (not found): {dir_path}")

# Clean files
import glob
for pattern in files_to_clean:
    files = glob.glob(pattern)
    for file_path in files:
        if os.path.exists(file_path):
            print(f"🗑️  Deleting: {file_path}")
            os.remove(file_path)
            print(f"   ✅ Deleted")

# Keep dataset
print(f"\n✅ Cleanup complete!")
print(f"📁 Your dataset is still in: /content/data_raw")
print(f"   (This was NOT deleted)")

# Verify dataset is still there
if os.path.exists('/content/data_raw'):
    folders = [f for f in os.listdir('/content/data_raw') if os.path.isdir(os.path.join('/content/data_raw', f))]
    print(f"\n📊 Dataset status:")
    print(f"   Folders: {len(folders)}")
    print(f"   Dataset location: /content/data_raw")
else:
    print(f"\n⚠️  Dataset not found in /content/data_raw")
```

---

## 🎯 Complete Cleanup (More Aggressive)

**If you want to delete EVERYTHING except the dataset:**

```python
import os
import shutil
import glob

print("🧹 Complete cleanup - Deleting everything except dataset...\n")

# List of things to keep
KEEP = ['/content/data_raw', '/content/drive']  # Keep dataset and Google Drive

# Get all items in /content
all_items = os.listdir('/content')

deleted_count = 0
kept_count = 0

for item in all_items:
    item_path = os.path.join('/content', item)
    
    # Skip if in keep list
    if item_path in KEEP or item_path.startswith('/content/drive'):
        print(f"✅ Keeping: {item_path}")
        kept_count += 1
        continue
    
    try:
        if os.path.isdir(item_path):
            print(f"🗑️  Deleting directory: {item_path}")
            shutil.rmtree(item_path)
            deleted_count += 1
        elif os.path.isfile(item_path):
            print(f"🗑️  Deleting file: {item_path}")
            os.remove(item_path)
            deleted_count += 1
    except Exception as e:
        print(f"⚠️  Could not delete {item_path}: {str(e)}")

print(f"\n✅ Cleanup complete!")
print(f"   Deleted: {deleted_count} items")
print(f"   Kept: {kept_count} items")
print(f"\n📁 Your dataset is still in: /content/data_raw")

# Verify dataset
if os.path.exists('/content/data_raw'):
    folders = [f for f in os.listdir('/content/data_raw') if os.path.isdir(os.path.join('/content/data_raw', f))]
    print(f"   Dataset folders: {len(folders)}")
else:
    print(f"\n⚠️  Dataset not found!")
```

---

## 🎯 Selective Cleanup (Recommended)

**Delete only processed files, keep dataset and notebook:**

```python
import os
import shutil

print("🧹 Selective cleanup...\n")

# Delete processed data
if os.path.exists('/content/output'):
    print("🗑️  Deleting /content/output (processed data, logs, plots)...")
    shutil.rmtree('/content/output')
    print("   ✅ Deleted")

# Delete models
if os.path.exists('/content/models'):
    print("🗑️  Deleting /content/models (trained models)...")
    shutil.rmtree('/content/models')
    print("   ✅ Deleted")

# Delete any zip files
import glob
zip_files = glob.glob('/content/*.zip')
for zip_file in zip_files:
    print(f"🗑️  Deleting: {zip_file}")
    os.remove(zip_file)
    print("   ✅ Deleted")

# Keep dataset
print(f"\n✅ Cleanup complete!")
print(f"📁 Kept: /content/data_raw (your dataset)")
print(f"📁 Kept: /content/drive (Google Drive)")

# Verify dataset
if os.path.exists('/content/data_raw'):
    folders = [f for f in os.listdir('/content/data_raw') if os.path.isdir(os.path.join('/content/data_raw', f))]
    print(f"\n📊 Dataset status:")
    print(f"   ✅ Dataset intact: {len(folders)} folders")
    print(f"   Location: /content/data_raw")
else:
    print(f"\n⚠️  Dataset not found!")
```

---

## ✅ What Gets Deleted

- ✅ `/content/output/` - Processed data, training logs, plots
- ✅ `/content/models/` - Trained models (.h5 files)
- ✅ `/content/*.zip` - Downloaded model files
- ✅ `/content/*.pkl` - Processed data files
- ✅ `/content/*.csv` - Training logs
- ✅ `/content/*.png` - Plots and visualizations

## ✅ What Gets Kept

- ✅ `/content/data_raw/` - **Your original dataset** (NOT deleted)
- ✅ `/content/drive/` - Google Drive (NOT deleted)
- ✅ Your notebook (if saved in Drive)

---

## 🎯 Quick Cleanup (One Line)

**Fastest way to clean:**

```python
# Quick cleanup - delete output and models only
import shutil
shutil.rmtree('/content/output', ignore_errors=True)
shutil.rmtree('/content/models', ignore_errors=True)
print("✅ Cleaned up! Dataset still in /content/data_raw")
```

---

## ⚠️ Important Notes

1. **Dataset is NOT deleted** - Your videos in `/content/data_raw` are safe
2. **Google Drive is NOT deleted** - Your Drive files are safe
3. **This is irreversible** - Make sure you've downloaded models if needed
4. **Notebook stays** - Your Colab notebook is not deleted

---

## 📋 Quick Checklist

Before cleanup:
- [ ] Downloaded model files (if needed)
- [ ] Saved notebook to Drive (if needed)
- [ ] Verified dataset location

After cleanup:
- [ ] Dataset still in `/content/data_raw`
- [ ] Can reprocess videos if needed
- [ ] Clean environment ready for new training

---

**Use the selective cleanup code above - it's the safest option! 🧹**



