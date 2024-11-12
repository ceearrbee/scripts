#!/bin/bash

# Directories
SOURCE_DIR="images"
THUMBNAIL_DIR="${SOURCE_DIR}/thumbnails"
RSS_FILE="gallery_feed.xml"  # RSS feed file

# Thumbnail dimensions
THUMB_WIDTH=400  # Width of the thumbnails in pixels

# HTML file and log file
HTML_FILE="index.html"
LOG_FILE="update_gallery.log"

# Start a new log file or clear the old one
echo "Starting update process - $(date)" > "$LOG_FILE"

# Ensure the source and thumbnail directories exist
echo "Checking if source directory exists..." | tee -a "$LOG_FILE"
if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory $SOURCE_DIR does not exist." | tee -a "$LOG_FILE"
  exit 1
fi

echo "Creating thumbnail directory if it doesn't exist..." | tee -a "$LOG_FILE"
mkdir -p "$THUMBNAIL_DIR" || { echo "Failed to create thumbnail directory $THUMBNAIL_DIR" | tee -a "$LOG_FILE"; exit 1; }

# Collect current images in the images directory (supports .jpg and .png files)
echo "Collecting images from $SOURCE_DIR..." | tee -a "$LOG_FILE"
current_images=""
found_images=false
new_images=""

for image in "$SOURCE_DIR"/*.{jpg,png}; do
  if [ -e "$image" ]; then
    found_images=true
    filename=$(basename "$image")
    current_images="$current_images $filename"
    echo "Detected image file: $image" | tee -a "$LOG_FILE"

    # Check if the image is new by checking if it exists in the RSS feed
    if ! grep -q "$filename" "$RSS_FILE"; then
      new_images="$new_images $filename"
      echo "New image detected: $filename" | tee -a "$LOG_FILE"
    fi
  fi
done

# If no images were found, log it clearly and exit early
if [ "$found_images" = false ]; then
  echo "No .jpg or .png files detected in $SOURCE_DIR. Exiting." | tee -a "$LOG_FILE"
  exit 1
fi

# Log found images
echo "Images to process: $current_images" | tee -a "$LOG_FILE"

# Generate thumbnails for each image
for image in $current_images; do
  thumbnail_path="$THUMBNAIL_DIR/$image"
  if [ ! -f "$thumbnail_path" ]; then
    echo "Creating thumbnail for $image..." | tee -a "$LOG_FILE"
    if convert "$SOURCE_DIR/$image" -thumbnail "${THUMB_WIDTH}x" "$thumbnail_path" 2>>"$LOG_FILE"; then
      echo "Thumbnail created for $image" | tee -a "$LOG_FILE"
    else
      echo "Error creating thumbnail for $image" | tee -a "$LOG_FILE"
    fi
  else
    echo "Thumbnail already exists for $image" | tee -a "$LOG_FILE"
  fi
done

# Build the image list for the HTML file
echo "Building image list for HTML file..." | tee -a "$LOG_FILE"
updated_images=$(echo "$current_images" | awk '{for(i=1;i<=NF;i++) printf "\""$i"\","}')
updated_images=${updated_images%,} # Remove trailing comma
echo "Updated image list for HTML: $updated_images" | tee -a "$LOG_FILE"

# Update or insert <photo-gallery> tag in the HTML file
if grep -q '<photo-gallery images=' "$HTML_FILE"; then
  echo "Updating existing <photo-gallery> tag in $HTML_FILE..." | tee -a "$LOG_FILE"
  sed -i '/<photo-gallery images=/c\
  <photo-gallery images=['"$updated_images"']></photo-gallery>' "$HTML_FILE" 2>>"$LOG_FILE"
else
  echo "Inserting new <photo-gallery> tag in $HTML_FILE..." | tee -a "$LOG_FILE"
  sed -i "/<\/body>/i <photo-gallery images=[$updated_images]></photo-gallery>" "$HTML_FILE" 2>>"$LOG_FILE"
fi

# Create or update the RSS feed
if [ ! -f "$RSS_FILE" ]; then
  echo "Creating new RSS feed at $RSS_FILE..." | tee -a "$LOG_FILE"
  cat <<EOF > "$RSS_FILE"
<?xml version="1.0" encoding="UTF-8" ?>
<?xml-stylesheet type="text/xsl" href="rss-style.xsl"?>
<rss version="2.0">
  <channel>
    <title>Photo Gallery Update</title>
    <link>https://www.site.com/gallery</link>
    <description>Updates when new images are added to the gallery.</description>
    <language>en-us</language>
    <lastBuildDate>$(date -R)</lastBuildDate>
    <copyright>Copyright © </copyright>
    <managingEditor>gallery@site.com (You)</managingEditor>
EOF
fi

# Add new entries for new images to the RSS feed
if [ -n "$new_images" ]; then
  echo "Adding new images to RSS feed..." | tee -a "$LOG_FILE"
  
  # Remove closing tags if they exist to ensure items are appended correctly
  sed -i '/<\/channel>/d' "$RSS_FILE"
  sed -i '/<\/rss>/d' "$RSS_FILE"

  # Append new image entries
  for image in $new_images; do
    cat <<EOF >> "$RSS_FILE"
    <item>
    <title>New Image: $image</title>
    <link>https://site.com/gallery/images/$image</link>
    <description>New image added to the gallery: $image</description>
    <pubDate>$(date -R)</pubDate>
    <guid>https://site.com/gallery/images/$image</guid>
    <author>gallery@site.com (You)</author>
    <category>Photography</category>
    <enclosure url="https://site.com/gallery/images/$image" type="image/jpeg"/>
    </item>
EOF
  done

  # Add closing tags for RSS feed
  echo "</channel>" >> "$RSS_FILE"
  echo "</rss>" >> "$RSS_FILE"
fi

# Update or add Last Updated timestamp in the last-updated div in index.html
last_updated="Last updated: $(date +'%Y-%m-%d %H:%M:%S')"
echo "Setting last updated timestamp to '$last_updated'" | tee -a "$LOG_FILE"

if grep -q '<div class="last-updated">' "$HTML_FILE"; then
  echo "Updating existing <div class=\"last-updated\"> in $HTML_FILE..." | tee -a "$LOG_FILE"
  sed -i "s|<div class=\"last-updated\">.*</div>|<div class=\"last-updated\">$last_updated</div>|" "$HTML_FILE" 2>>"$LOG_FILE"
else
  echo "Appending new <div class=\"last-updated\"> to $HTML_FILE..." | tee -a "$LOG_FILE"
  sed -i "/<\/body>/i <div class=\"last-updated\">$last_updated</div>" "$HTML_FILE" 2>>"$LOG_FILE"
fi

echo "Gallery update completed" | tee -a "$LOG_FILE"
