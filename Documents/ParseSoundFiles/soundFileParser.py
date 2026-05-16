import os
import re
import requests
from bs4 import BeautifulSoup

# Audio extensions to include
AUDIO_EXTENSIONS = {
    ".wav", ".mp3", ".ogg", ".flac",
    ".aiff", ".m4a"
}

# Match filenames starting with:
# 854332_qubodup_name.wav
# 854332 qubodup name.wav
FREESOUND_PATTERN = re.compile(
    r"^(\d+)[ _-]+([A-Za-z0-9_-]+)",
    re.IGNORECASE
)

OUTPUT_FILE = "audacity_freesound_report.txt"


def is_audio_file(filename):
    ext = os.path.splitext(filename)[1].lower()
    return ext in AUDIO_EXTENSIONS


def find_projects(root_folder):
    projects = []

    for dirpath, dirnames, filenames in os.walk(root_folder):
        for file in filenames:
            if file.lower().endswith((".aup", ".aup3")):
                projects.append(os.path.join(dirpath, file))

    return projects


def fetch_license(sound_id, author):
    url = f"https://freesound.org/people/{author}/sounds/{sound_id}/"

    try:
        response = requests.get(
            url,
            headers={
                "User-Agent": "Mozilla/5.0"
            },
            timeout=15
        )

        if response.status_code != 200:
            return {
                "url": url,
                "error": f"HTTP {response.status_code}"
            }

        soup = BeautifulSoup(response.text, "html.parser")

        # Freesound usually has license links containing "creativecommons"
        license_link = soup.find(
            "a",
            href=lambda h: h and (
                "creativecommons.org" in h
                or "sampling+" in h
            )
        )

        if license_link:
            license_name = license_link.get_text(strip=True)
            license_url = license_link.get("href")

            return {
                "url": url,
                "license_name": license_name,
                "license_url": license_url
            }

        return {
            "url": url,
            "error": "License not found"
        }

    except Exception as e:
        return {
            "url": url,
            "error": str(e)
        }


def process_project(project_path, output_lines):
    folder = os.path.dirname(project_path)

    output_lines.append("=" * 70)
    output_lines.append(f"PROJECT: {project_path}")
    output_lines.append("")

    audio_files = []

    for file in os.listdir(folder):
        full_path = os.path.join(folder, file)

        if os.path.isfile(full_path) and is_audio_file(file):
            audio_files.append(file)

    output_lines.append("FILES:")
    for file in sorted(audio_files):
        output_lines.append(file)

    output_lines.append("")
    output_lines.append("FREESOUND LICENSES:")
    output_lines.append("")

    for file in sorted(audio_files):
        match = FREESOUND_PATTERN.match(file)

        if not match:
            continue

        sound_id = match.group(1)
        author = match.group(2)

        info = fetch_license(sound_id, author)

        output_lines.append(f"File: {file}")
        output_lines.append(f"URL: {info['url']}")

        if "error" in info:
            output_lines.append(f"Error: {info['error']}")
        else:
            output_lines.append(
                f"License: {info['license_name']}"
            )
            output_lines.append(
                f"License URL: {info['license_url']}"
            )

        output_lines.append("")

    output_lines.append("")
    output_lines.append("")


def main():
    root_folder = input("Root folder: ").strip()

    projects = find_projects(root_folder)

    if not projects:
        print("No Audacity projects found.")
        return

    output_lines = []

    for project in projects:
        print(f"Processing: {project}")
        process_project(project, output_lines)

    with open(OUTPUT_FILE, "w", encoding="utf-8") as f:
        f.write("\n".join(output_lines))

    print(f"\nDone.")
    print(f"Report written to: {OUTPUT_FILE}")


if __name__ == "__main__":
    main()
