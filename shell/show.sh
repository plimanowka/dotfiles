# Universal file viewer with nice rendering

show() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    cat <<'EOF'
show - Universal file viewer with syntax highlighting and rendering

Usage: show [options] [file|-]

Supported formats:
  Markdown (.md)         → rendered with glow
  PDF (.pdf)             → rendered as images (page by page)
  JSON (.json)           → syntax highlighted with bat
  YAML (.yaml, .yml)     → syntax highlighted with bat
  XML (.xml)             → syntax highlighted with bat
  Images (.jpg, .png, .svg, .gif, etc.) → displayed with imgcat
  Code & text files      → syntax highlighted with bat

Examples:
  show README.md
  show document.pdf
  show document.pdf -p 1-3      # pages 1-3 only
  show config.json
  show deployment.yaml
  show photo.jpg
  curl -s https://api.example.com | show -t json

Options:
  -t, --type TYPE    Force file type (json, yaml, xml, md, pdf, image, etc.)
  -p, --pages RANGE  PDF page range (e.g., 1, 1-5, 2-4)
  -h, --help         Show this help

Dependencies: glow, bat, imgcat, imagemagick, librsvg, poppler
EOF
    return 0
  fi

  local file=""
  local forced_type=""
  local pdf_pages=""

  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -t|--type)
        forced_type="$2"
        shift 2
        ;;
      -p|--pages)
        pdf_pages="$2"
        shift 2
        ;;
      *)
        file="$1"
        shift
        ;;
    esac
  done

  # Determine file type
  local ext=""
  if [[ -n "$forced_type" ]]; then
    ext="$forced_type"
  elif [[ -n "$file" && "$file" != "-" ]]; then
    ext="${file##*.}"
    ext="${ext:l}"  # lowercase
  fi

  # Handle stdin
  if [[ -z "$file" || "$file" == "-" ]]; then
    if [[ -z "$ext" ]]; then
      # No type specified, use bat with auto-detect
      bat --paging=auto --style=plain
    else
      case "$ext" in
        md|markdown)
          glow -p -
          ;;
        jpg|jpeg|png|gif|bmp|tiff|webp|svg|image)
          imgcat
          ;;
        *)
          bat --paging=auto --style=plain -l "$ext"
          ;;
      esac
    fi
    return
  fi

  # Check file exists
  if [[ ! -f "$file" ]]; then
    echo "show: file not found: $file" >&2
    return 1
  fi

  # Render based on extension
  case "$ext" in
    md|markdown)
      glow -p "$file"
      ;;
    pdf)
      _show_pdf "$file" "$pdf_pages"
      ;;
    jpg|jpeg|png|gif|bmp|tiff|webp)
      magick "$file" -resize '1200x>' - | imgcat
      ;;
    svg)
      rsvg-convert "$file" | imgcat
      ;;
    *)
      bat --paging=auto --style=plain "$file"
      ;;
  esac
}

# Helper function to render PDF pages
_show_pdf() {
  local file="$1"
  local pages="$2"
  local tmpdir=$(mktemp -d)
  local first_page=1
  local last_page=""

  # Get total pages
  local total_pages=$(pdfinfo "$file" 2>/dev/null | grep "^Pages:" | awk '{print $2}')

  if [[ -z "$total_pages" ]]; then
    echo "show: could not read PDF: $file" >&2
    rm -rf "$tmpdir"
    return 1
  fi

  # Parse page range
  if [[ -n "$pages" ]]; then
    if [[ "$pages" =~ ^([0-9]+)$ ]]; then
      first_page=$pages
      last_page=$pages
    elif [[ "$pages" =~ ^([0-9]+)-([0-9]+)$ ]]; then
      first_page=${match[1]}
      last_page=${match[2]}
    else
      echo "show: invalid page range: $pages" >&2
      rm -rf "$tmpdir"
      return 1
    fi
  else
    last_page=$total_pages
  fi

  echo "Rendering pages $first_page-$last_page of $total_pages..."

  # Render pages to images
  pdftoppm -png -r 150 -f "$first_page" -l "$last_page" "$file" "$tmpdir/page"

  # Display each page
  for img in "$tmpdir"/page-*.png; do
    [[ -f "$img" ]] || continue
    local page_num=$(basename "$img" | sed 's/page-0*\([0-9]*\)\.png/\1/')
    echo "\n── Page $page_num ──"
    imgcat "$img"
  done

  rm -rf "$tmpdir"
}

# Completion: all files
_show() {
  _arguments \
    '-t[Force file type]:type:(json yaml xml md markdown pdf image)' \
    '--type[Force file type]:type:(json yaml xml md markdown pdf image)' \
    '-p[PDF page range]:pages:' \
    '--pages[PDF page range]:pages:' \
    '-h[Show help]' \
    '--help[Show help]' \
    '*:file:_files'
}

compdef _show show
