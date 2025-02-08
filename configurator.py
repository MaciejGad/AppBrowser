import json
import os
import plistlib
import requests
import subprocess
from PIL import Image, ImageDraw

# Ścieżki do plików
CONFIG_FILE = "config.json"
INFO_PLIST_PATH = "./AppBrowser/Info.plist"
ICON_OUTPUT_PATH = "./AppBrowser/Assets.xcassets/AppIcon.appiconset/icon.png"
ICON_GEN_SCRIPT = "./icon_gen"

def load_config():
    with open(CONFIG_FILE, "r") as f:
        return json.load(f)

def update_info_plist(app_name, app_url):
    with open(INFO_PLIST_PATH, "rb") as f:
        plist = plistlib.load(f)
    
    plist["CFBundleDisplayName"] = app_name
    plist["CFBundleName"] = app_name
    plist["AppURL"] = app_url
    
    with open(INFO_PLIST_PATH, "wb") as f:
        plistlib.dump(plist, f)
    print(f"Zaktualizowano Info.plist dla {app_name}")

def download_icon(icon_url):
    response = requests.get(icon_url, stream=True)
    if response.status_code == 200:
        with open(ICON_OUTPUT_PATH, "wb") as f:
            for chunk in response.iter_content(1024):
                f.write(chunk)
        print("Pobrano ikonę aplikacji")
    else:
        print("Błąd pobierania ikony, używam domyślnej generacji")
        return False
    return True

def generate_icon(color):
    size = (1024, 1024)
    img = Image.new("RGB", size, color)
    draw = ImageDraw.Draw(img)
    draw.text((size[0]//2 - 50, size[1]//2 - 50), "App", fill="white")
    img.save(ICON_OUTPUT_PATH)
    print("Wygenerowano ikonę aplikacji")

def run_icon_gen(icon_name):
    result = subprocess.run([ICON_GEN_SCRIPT, icon_name, ICON_OUTPUT_PATH], capture_output=True, text=True)
    if result.returncode == 0:
        print(f"Wygenerowano ikonę aplikacji przy użyciu {ICON_GEN_SCRIPT}")
    else:
        print(f"Błąd generowania ikony: {result.stderr}")
        generate_icon("#0000FF")

def main():
    config = load_config()
    
    app_name = config["app_name"]
    app_url = config["app_url"]
    icon_color = config.get("icon_color", "#0000FF")
    icon_url = config.get("icon_url", None)
    icon_name = config.get("icon_name", None)
    
    update_info_plist(app_name, app_url)
    
    if icon_name:
        run_icon_gen(icon_name)
    elif icon_url:
        if not download_icon(icon_url):
            generate_icon(icon_color)
    else:
        generate_icon(icon_color)
    
if __name__ == "__main__":
    main()
