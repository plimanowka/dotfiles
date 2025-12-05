# Display images in terminal (iTerm2)

showimg() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
showimg - Display images in iTerm2 terminal

Usage: showimg [file|-]

Arguments:
  file    Image file to display (svg, jpg, png, gif, bmp, tiff, webp)
  -       Read image from stdin (or omit argument)

Features:
  - SVG files are converted via rsvg-convert
  - Raster images are resized to max 1200px width via ImageMagick
  - Other formats passed directly to imgcat

Examples:
  showimg photo.jpg
  showimg diagram.svg
  curl -s https://example.com/image.png | showimg
  cat image.png | showimg -

Dependencies: imgcat, rsvg-convert (for SVG), imagemagick (for resizing)
EOF
    return 0
  fi

  # Handle stdin/pipe
  if [[ -z "$1" || "$1" == "-" ]]; then
    imgcat
    return
  fi

  local file="$1"

  if [[ ! -f "$file" ]]; then
    echo "showimg: file not found: $file" >&2
    return 1
  fi

  local ext="${file##*.}"
  ext="${ext:l}"  # lowercase

  case "$ext" in
    svg)
      rsvg-convert "$file" | imgcat
      ;;
    jpg|jpeg|png|gif|bmp|tiff|webp)
      magick "$file" -resize '1200x>' - | imgcat
      ;;
    *)
      imgcat "$file"
      ;;
  esac
}

# Completion: image files only
_showimg() {
  _files -g '*.(#i)(svg|jpg|jpeg|png|gif|bmp|tiff|webp)'
}

compdef _showimg showimg
