#!/bin/bash
# For Windows, save as setup.bat and remove the shebang line

# Initialize pipenv environment
pipenv --python 3.9

# Install dependencies
pipenv install requests
pipenv install yt-dlp

# Check if ffmpeg is installed
echo "Checking for ffmpeg..."
if command -v ffmpeg >/dev/null 2>&1; then
    echo "ffmpeg is installed"
else
    echo "WARNING: ffmpeg is not installed. You need to install it separately."
    echo "On Windows: Install with Chocolatey: choco install ffmpeg"
    echo "On macOS: Install with Homebrew: brew install ffmpeg"
    echo "On Linux: Use your package manager, e.g., apt install ffmpeg"
fi

echo "Setup complete. Run the script with: pipenv run pipenv run python bav_downloader.py"
