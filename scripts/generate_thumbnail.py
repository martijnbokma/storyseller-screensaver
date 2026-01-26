#!/usr/bin/env python3
"""
Generate a thumbnail image for StorySellerSaver screensaver.
Creates a 1280x800 PNG that represents the screensaver design.
"""

from PIL import Image, ImageDraw, ImageFont, ImageFilter
import os
import sys

# Configuration matching ScreensaverConfiguration.swift
WORDS = ["create", "develop", "produce", "manage", "sell"]
CENTER_TEXT = "the story"
LOGO_TEXT = "CREATIVE BUSINESS"

# Colors (approximating the dark blue gradient)
BG_TOP = (13, 15, 20)      # Dark blue-gray
BG_BOTTOM = (3, 5, 8)      # Almost black
TEXT_COLOR = (255, 255, 255)  # White
LOGO_COLOR = (255, 255, 255)  # White with alpha

# Dimensions
WIDTH = 1280
HEIGHT = 800

def create_thumbnail():
    """Create a thumbnail image representing the screensaver."""

    # Create image with gradient background
    img = Image.new('RGB', (WIDTH, HEIGHT), BG_BOTTOM)
    draw = ImageDraw.Draw(img)

    # Draw gradient background (simplified - top to bottom)
    for y in range(HEIGHT):
        ratio = y / HEIGHT
        r = int(BG_TOP[0] * (1 - ratio) + BG_BOTTOM[0] * ratio)
        g = int(BG_TOP[1] * (1 - ratio) + BG_BOTTOM[1] * ratio)
        b = int(BG_TOP[2] * (1 - ratio) + BG_BOTTOM[2] * ratio)
        draw.line([(0, y), (WIDTH, y)], fill=(r, g, b))

    # Try to load system fonts, fallback to default
    try:
        # Try macOS system fonts first
        story_font_size = 72
        word_font_size = int(story_font_size * 0.92)
        logo_font_size = int(WIDTH * 0.025)

        # Try to use system fonts
        story_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", story_font_size)
        word_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", word_font_size)
        logo_font = ImageFont.truetype("/System/Library/Fonts/Supplemental/Arial.ttf", logo_font_size)
    except:
        # Fallback to default font
        story_font = ImageFont.load_default()
        word_font = ImageFont.load_default()
        logo_font = ImageFont.load_default()

    # Calculate positions
    center_x = WIDTH // 2
    center_y = HEIGHT // 2 - 25  # Slight vertical offset

    # Draw "create" word (left side, centered vertically)
    word_text = "create"
    word_bbox = draw.textbbox((0, 0), word_text, font=word_font)
    word_width = word_bbox[2] - word_bbox[0]
    word_height = word_bbox[3] - word_bbox[1]
    word_x = center_x - 200  # Gap between word and "the story"
    word_y = center_y - word_height // 2

    # Draw word with shadow effect
    shadow_offset = 3
    draw.text((word_x + shadow_offset, word_y + shadow_offset), word_text,
              fill=(0, 0, 0, 128), font=word_font)
    draw.text((word_x, word_y), word_text, fill=TEXT_COLOR, font=word_font)

    # Draw "the story" (center)
    story_bbox = draw.textbbox((0, 0), CENTER_TEXT, font=story_font)
    story_width = story_bbox[2] - story_bbox[0]
    story_height = story_bbox[3] - story_bbox[1]
    story_x = center_x - story_width // 2
    story_y = center_y - story_height // 2

    # Draw "the story" with stronger shadow/glow
    glow_radius = 16
    for offset in range(glow_radius):
        alpha = int(255 * 0.07 * (1 - offset / glow_radius))
        draw.text((story_x + offset, story_y + offset), CENTER_TEXT,
                 fill=(255, 255, 255, alpha), font=story_font)

    draw.text((story_x, story_y), CENTER_TEXT, fill=TEXT_COLOR, font=story_font)

    # Draw "CREATIVE BUSINESS" logo (bottom, smaller, semi-transparent)
    logo_bbox = draw.textbbox((0, 0), LOGO_TEXT, font=logo_font)
    logo_width = logo_bbox[2] - logo_bbox[0]
    logo_height = logo_bbox[3] - logo_bbox[1]
    logo_x = center_x - logo_width // 2
    logo_y = center_y + 150  # Below the carousel

    # Draw logo with reduced opacity
    logo_color = (255, 255, 255, int(255 * 0.3))
    draw.text((logo_x, logo_y), LOGO_TEXT, fill=logo_color, font=logo_font)

    # Add subtle vignette effect (darker edges)
    vignette = Image.new('RGBA', (WIDTH, HEIGHT), (0, 0, 0, 0))
    vignette_draw = ImageDraw.Draw(vignette)

    # Draw radial gradient for vignette
    center = (WIDTH // 2, HEIGHT // 2)
    max_dist = (WIDTH ** 2 + HEIGHT ** 2) ** 0.5

    for y in range(0, HEIGHT, 10):
        for x in range(0, WIDTH, 10):
            dist = ((x - center[0]) ** 2 + (y - center[1]) ** 2) ** 0.5
            alpha = int(255 * 0.45 * (dist / max_dist))
            if alpha > 0:
                vignette_draw.rectangle([x, y, x+10, y+10], fill=(0, 0, 0, min(alpha, 115)))

    # Composite vignette
    img = Image.alpha_composite(img.convert('RGBA'), vignette).convert('RGB')

    return img

def main():
    """Generate and save the thumbnail."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    project_root = os.path.dirname(script_dir)
    output_path = os.path.join(project_root, "StorySellerSaver", "Preview.png")

    print(f"Generating thumbnail: {output_path}")

    try:
        thumbnail = create_thumbnail()
        thumbnail.save(output_path, "PNG", optimize=True)
        print(f"✅ Thumbnail generated successfully: {output_path}")
        print(f"   Size: {WIDTH}x{HEIGHT} pixels")
        return 0
    except Exception as e:
        print(f"❌ Error generating thumbnail: {e}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    sys.exit(main())
