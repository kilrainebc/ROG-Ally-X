import os
import requests
import subprocess
import sys
import re
from urllib.parse import urlparse, parse_qs

videos = {
    # SONY
    "ps1":"https://steamdeckrepo.com/post/QEzrE/playstation_1",
    "ps_abstract":"https://steamdeckrepo.com/post/nvMx8/playstation_abstract",
    "ps2":"https://www.youtube.com/watch?v=y9Ln-qyvX_I",
    # NINTENDO
    "snes":"https://www.youtube.com/watch?v=QNwOaGLG8CI",
    "gba":"https://steamdeckrepo.com/post/1E1Ln/gameboy_advance",
    "gamecube":"https://steamdeckrepo.com/post/E1Zza/gamecube",
    # OTHER
    "pokemon_firered":"https://steamdeckrepo.com/post/Y6D4n/pokemon_opening_animation_on_steam_deck"
}

def check_ffmpeg():
    """
    check system for ffmpeg
    """
    try:
        subprocess.run(["ffmpeg", "-version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except FileNotFoundError:
        print("ERROR: FFmpeg is not installed or not in your PATH.")
        print("Please install FFmpeg to continue:")
        print("  - Windows: Install with Chocolatey: choco install ffmpeg")
        print("  - macOS: Install with Homebrew: brew install ffmpeg")
        print("  - Linux: Use your package manager, e.g., apt install ffmpeg")
        return False

def check_yt_dlp():
    """
    Check system for yt-dlp
    """
    try:
        subprocess.run(["yt-dlp", "--version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return True
    except FileNotFoundError:
        print("WARNING: yt-dlp is not installed. It's required for YouTube downloads.")
        print("Please install yt-dlp:")
        print("  - pip install yt-dlp")
        print("  - Or on macOS: brew install yt-dlp")
        return False

def ensure_output_directory():
    """
    Ensure the output directory exists
    """
    output_dir = "../../boot-animations/videos"
    if not os.path.exists(output_dir):
        try:
            os.makedirs(output_dir, exist_ok=True)
            print(f"Created output directory: {output_dir}")
        except Exception as e:
            print(f"Error creating output directory: {e}")
            sys.exit(1)

def check_mp4_exists(name: str):
    """
    Check if an MP4 file with this name already exists
    Returns the file path if it exists, None otherwise
    """
    name = name.replace(" ", "_")
    mp4_path = os.path.join("../../boot-animations/videos", f"{name}.mp4")
    if os.path.exists(mp4_path):
        return mp4_path
    return None

def convert_to_mp4(filepath: str, name: str, target_resolution="1920x1080"):
    """
    Convert webm file to mp4 using ffmpeg
    Returns the filepath of the converted file
    Target resolution parameter allows forcing to specific resolution
    """
    if not filepath or not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return None
    
    # Set output filename based on the custom name
    name_safe = name.replace(" ", "_")
    output_path = os.path.join("../../boot-animations/videos", f"{name_safe}.mp4")
    
    # Build ffmpeg command with resolution scaling
    ffmpeg_cmd = [
        "ffmpeg", 
        "-i", filepath, 
        "-c:v", "h264", 
        "-c:a", "aac",
        "-vf", f"scale={target_resolution}", 
        "-pix_fmt", "yuv420p",  # Ensure compatibility
        "-movflags", "+faststart",  # Optimize for web streaming
        "-y",  # Overwrite output file if exists
        output_path
    ]
    
    # Run ffmpeg command
    try:
        subprocess.run(ffmpeg_cmd, check=True)
        print(f"Converted to {output_path}")
        return output_path
    except subprocess.CalledProcessError as e:
        print(f"Conversion failed: {e}")
        return None

def delete_webm(filepath: str):
    """
    Delete the WebM file after successful conversion
    Returns True if deleted successfully, False otherwise
    """
    try:
        if os.path.exists(filepath):
            os.remove(filepath)
            print(f"Deleted WebM file: {filepath}")
            return True
        else:
            print(f"WebM file not found: {filepath}")
            return False
    except Exception as e:
        print(f"Error deleting WebM file: {e}")
        return False

def is_youtube_url(url):
    """Determine if a URL is from YouTube"""
    return 'youtube.com' in url or 'youtu.be' in url

def is_steamdeckrepo_url(url):
    """Determine if a URL is from SteamDeckRepo"""
    return 'steamdeckrepo.com' in url

def download_steamdeckrepo_video(url, name):
    """
    Download video from steamdeckrepo.com
    Returns filepath of downloaded file
    """
    # Extract ID from URL
    parsed_url = urlparse(url)
    path_parts = parsed_url.path.strip('/').split('/')
    id = path_parts[-2]
    
    # Download from SteamDeckRepo
    download_url = f"https://steamdeckrepo.com/post/download/{id}"
    print(f"Downloading from: {download_url}")
    
    # Set output filename based on the provided name
    name_safe = name.replace(" ", "_")
    output_path = os.path.join("../../boot-animations/videos", f"{name_safe}.webm")
    
    # Download file with requests
    response = requests.get(download_url, stream=True)
    
    # Check if download was successful
    if response.status_code == 200:
        with open(output_path, 'wb') as f:
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
        print(f"Downloaded to {output_path}")
        return output_path
    else:
        print(f"Failed to download: {response.status_code}")
        return None

def download_youtube_video(url, name):
    """
    Download video from YouTube
    Uses yt-dlp for better YouTube compatibility
    Returns filepath of downloaded file
    """
    # Prepare output path
    name_safe = name.replace(" ", "_")
    output_path = os.path.join("../../boot-animations/videos", f"{name_safe}.webm")
    
    # Use yt-dlp to download the video
    yt_dlp_cmd = [
        "yt-dlp",
        "-f", "bestvideo[ext=webm]+bestaudio[ext=webm]/best[ext=webm]/best",
        "-o", output_path,
        url
    ]
    
    try:
        print(f"Downloading YouTube video: {url}")
        subprocess.run(yt_dlp_cmd, check=True)
        print(f"Downloaded to {output_path}")
        return output_path
    except subprocess.CalledProcessError as e:
        print(f"Failed to download YouTube video: {e}")
        return None

def main():
    # Check for required tools
    if not check_ffmpeg():
        sys.exit(1)
    
    if not check_yt_dlp():
        sys.exit(1)

    # Ensure output directory exists
    ensure_output_directory()

    # Processing results tracking
    successful = []
    failed = []
    skipped = []

    # Process all videos in the dictionary
    for name, url in videos.items():
        print("\n" + "="*50)
        print(f"Processing: {name} from {url}")
        
        # Check if MP4 already exists with this name
        existing_mp4 = check_mp4_exists(name)
        if existing_mp4:
            print(f"⏭️ Skipping {name} - MP4 already exists: {existing_mp4}")
            skipped.append(name)
            continue
        
        # Determine URL type and download accordingly
        filepath = None
        if is_youtube_url(url) and check_yt_dlp():
            filepath = download_youtube_video(url, name)
        elif is_steamdeckrepo_url(url):
            filepath = download_steamdeckrepo_video(url, name)
        else:
            print(f"Unsupported URL format: {url}")
            failed.append(name)
            continue
        
        # Handle download result
        if filepath is None:
            print(f"❌ Failed to download {name}")
            failed.append(name)
            continue
            
        # Convert to MP4
        mp4_path = convert_to_mp4(filepath, name, "1920x1080")
        if mp4_path:
            # Delete the WebM file after successful conversion
            if delete_webm(filepath):
                print(f"✅ Successfully processed and cleaned up {name}")
            else:
                print(f"⚠️ Converted {name} but failed to delete WebM file")
            successful.append(name)
        else:
            print(f"❌ Failed to convert {name}")
            failed.append(name)
    
    # Print summary
    print("\n" + "="*50)
    print("--- Summary ---")
    print(f"Total videos: {len(videos)}")
    print(f"Successfully processed: {len(successful)}")
    print(f"Skipped (already exist): {len(skipped)}")
    print(f"Failed: {len(failed)}")
    
    if skipped:
        print("\nSkipped items (already exist):")
        for item in skipped:
            print(f"- {item}")
            
    if failed:
        print("\nFailed items:")
        for item in failed:
            print(f"- {item}")

if __name__ == "__main__":
    main()