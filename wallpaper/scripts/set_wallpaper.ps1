# Get full path to black.jpg in current directory
$imgPath = (Resolve-Path "..\black.jpg").Path

# Use COM object to set the background
$code = @"
using System.Runtime.InteropServices;
public class Wallpaper {
  [DllImport("user32.dll", SetLastError = true)]
  public static extern bool SystemParametersInfo(int uAction, int uParam, string lpvParam, int fuWinIni);
}
"@

Add-Type $code
[Wallpaper]::SystemParametersInfo(20, 0, $imgPath, 3)
