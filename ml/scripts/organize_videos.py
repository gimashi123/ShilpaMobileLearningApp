"""
Helper script to organize video files by number.

This script helps organize raw video files into folders by number.
It assumes videos are named with numbers (e.g., "1_video1.mp4", "200_video.mp4", etc.)

Usage:
    python organize_videos.py --input_dir /path/to/raw/videos --output_dir /path/to/data_raw
"""

import os
import shutil
import argparse
from pathlib import Path
import re


def extract_number_from_filename(filename):
    """
    Extract number from filename.
    
    Examples:
        "1_video.mp4" -> 1
        "number_200_video.avi" -> 200
        "210.mp4" -> 210
    """
    # Remove file extension
    name_without_ext = Path(filename).stem
    
    # Find all numbers in the filename
    numbers = re.findall(r'\d+', name_without_ext)
    
    if numbers:
        # Return the first (or largest) number found
        # You can modify this logic based on your naming convention
        return int(numbers[0])
    
    return None


def organize_videos(input_dir, output_dir, pattern=None):
    """
    Organize videos into folders by number.
    
    Args:
        input_dir: Directory containing raw video files
        output_dir: Directory to create organized structure
        pattern: Optional regex pattern to match filenames
    """
    input_path = Path(input_dir)
    output_path = Path(output_dir)
    
    # Create output directory
    output_path.mkdir(parents=True, exist_ok=True)
    
    # Supported video formats
    video_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv', '.webm']
    
    # Get all video files
    video_files = []
    for ext in video_extensions:
        video_files.extend(input_path.glob(f'*{ext}'))
        video_files.extend(input_path.glob(f'*{ext.upper()}'))
    
    print(f"Found {len(video_files)} video files")
    
    # Organize by number
    organized_count = 0
    skipped_count = 0
    
    for video_file in video_files:
        # Extract number from filename
        number = extract_number_from_filename(video_file.name)
        
        if number is None:
            print(f"Warning: Could not extract number from {video_file.name}, skipping...")
            skipped_count += 1
            continue
        
        # Create folder for this number
        number_folder = output_path / str(number)
        number_folder.mkdir(exist_ok=True)
        
        # Copy video to number folder
        dest_path = number_folder / video_file.name
        
        # Handle duplicate names
        if dest_path.exists():
            counter = 1
            stem = video_file.stem
            suffix = video_file.suffix
            while dest_path.exists():
                new_name = f"{stem}_{counter}{suffix}"
                dest_path = number_folder / new_name
                counter += 1
        
        shutil.copy2(video_file, dest_path)
        organized_count += 1
        print(f"Organized: {video_file.name} -> {number}/{dest_path.name}")
    
    print(f"\nOrganization complete!")
    print(f"Organized: {organized_count} files")
    print(f"Skipped: {skipped_count} files")
    print(f"Output directory: {output_path}")
    
    # Print summary
    number_folders = sorted([f for f in output_path.iterdir() if f.is_dir()])
    print(f"\nCreated {len(number_folders)} number folders:")
    for folder in number_folders:
        video_count = len(list(folder.glob('*')))
        print(f"  {folder.name}: {video_count} videos")


def main():
    parser = argparse.ArgumentParser(
        description='Organize video files by number for sign language training'
    )
    parser.add_argument(
        '--input_dir',
        type=str,
        required=True,
        help='Directory containing raw video files'
    )
    parser.add_argument(
        '--output_dir',
        type=str,
        required=True,
        help='Directory to create organized structure'
    )
    parser.add_argument(
        '--pattern',
        type=str,
        default=None,
        help='Optional regex pattern to match filenames'
    )
    
    args = parser.parse_args()
    
    if not os.path.exists(args.input_dir):
        print(f"Error: Input directory does not exist: {args.input_dir}")
        return
    
    organize_videos(args.input_dir, args.output_dir, args.pattern)


if __name__ == '__main__':
    main()



