#!/bin/sh

START_DIR="."

# Ignore pattern check (simple version)
should_ignore() {
  case "$1" in
    *".git"*) return 0 ;;
    *".gitignore"*) return 0 ;;
    *".gitattributes"*) return 0 ;;
    *".gitmodules"*) return 0 ;;
    *".ignore"*) return 0 ;;
  esac
  return 1
}

check_file_type() {
  file="$1"
  [ -f "$file" ] || return

  mimetype=$(file --mime-type -b "$file")
  extension=$(echo "$file" | awk -F. '{print tolower($NF)}')

  expected_mime=""

  case "$extension" in
    txt) expected_mime="text/plain" ;;
    md) expected_mime="text/markdown" ;;
    html|htm) expected_mime="text/html" ;;
    css) expected_mime="text/css" ;;
    js) expected_mime="application/javascript" ;;
    json) expected_mime="application/json" ;;
    xml) expected_mime="application/xml" ;;
    jpg|jpeg) expected_mime="image/jpeg" ;;
    png) expected_mime="image/png" ;;
    gif) expected_mime="image/gif" ;;
    pdf) expected_mime="application/pdf" ;;
    zip) expected_mime="application/zip" ;;
    tar) expected_mime="application/x-tar" ;;
    gz) expected_mime="application/gzip" ;;
    sh) expected_mime="text/x-shellscript" ;;
    py) expected_mime="text/x-python" ;;
    c) expected_mime="text/x-c" ;;
    cpp) expected_mime="text/x-c++" ;;
    mp3) expected_mime="audio/mpeg" ;;
    mp4) expected_mime="video/mp4" ;;
    ogg) expected_mime="audio/ogg" ;;
    wav) expected_mime="audio/x-wav" ;;
    *) expected_mime="" ;;
  esac

  if [ -n "$expected_mime" ]; then
    if [ "$mimetype" != "$expected_mime" ]; then
      echo "⚠️  Mismatch: $file (extension: .$extension, type: $mimetype)"
    fi
  else
    echo "ℹ️  Unknown extension: $file (type: $mimetype)"
  fi
}

# Traverse files
find "$START_DIR" -type f ! -path "*/.git/*" | while read file; do
  if ! should_ignore "$file"; then
    check_file_type "$file"
  fi
done
        