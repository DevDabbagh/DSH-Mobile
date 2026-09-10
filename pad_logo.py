from PIL import Image

def pad_image(input_path, output_path):
    img = Image.open(input_path).convert("RGBA")
    
    # Target size
    canvas_size = 1024
    
    # Calculate scale so max dimension is about 2/3 of canvas (around 682)
    max_dim = max(img.width, img.height)
    scale = (canvas_size * 0.6) / max_dim
    
    new_width = int(img.width * scale)
    new_height = int(img.height * scale)
    
    img = img.resize((new_width, new_height), Image.Resampling.LANCZOS)
    
    # Create solid #0A0A0A canvas
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (10, 10, 10, 255))
    
    # Calculate position to center the image
    x = (canvas_size - new_width) // 2
    y = (canvas_size - new_height) // 2
    
    canvas.paste(img, (x, y), img)
    canvas.save(output_path, "PNG")
    print(f"Saved padded logo to {output_path}")

pad_image('/Users/ahmed/4Me/2026 Projects/DontSkipHumanity/DSH Mobile/assets/logoForAppIcon.png', '/Users/ahmed/4Me/2026 Projects/DontSkipHumanity/DSH Mobile/assets/logoForAppIcon_padded.png')
