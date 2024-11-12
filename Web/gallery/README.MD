A simple web gallery using html, css, js, bash and ImageMagick.
---

# Installation

1. Deploy to your web server with index.html where you want it to be served from.
2. Place all images in the /images folder.
3. Update index.html and update.sh to reflect your sites name/url/etc. 
4. Run 'update.sh'. It should output that it generated the thumbnails, modified the index page and generated the RSS feed.
5. Rerun whenever you add more photos/remove photos.

# Features
* Thumbnail generation.
* Styled RSS feed generation.
* Dynamically adding/removing photos from the gallery.
* Aria/Accessible lightbox.

# Notes

* Requires ImageMagick to be installed.
* Filenames cannot not contain spaces.
* Supports jpg and png only.
* Does not provide a fallback if JS is not available. 
* Tested on AlmaLinux 8 with Caddy.
* Proof of concept, not rigorously tested. 
* Poorly created by hand, not by AI!

