#!/usr/bin/env bats

setup() {
    TMPDIR=$(mktemp -d)
    cp Web/gallery/index.html "$TMPDIR/"
    cp Web/gallery/update.sh "$TMPDIR/"
    mkdir "$TMPDIR/images"
    convert -size 1x1 xc:white "$TMPDIR/images/sample.jpg"
    cd "$TMPDIR"
}

teardown() {
    rm -rf "$TMPDIR"
}

@test "update.sh builds gallery" {
    run bash update.sh
    [ "$status" -eq 0 ]
    [ -f images/thumbnails/sample.jpg ]
    [ -f gallery_feed.xml ]
    grep -Fq '<photo-gallery images=["sample.jpg"]></photo-gallery>' index.html
    grep -q 'Last updated:' index.html
}
