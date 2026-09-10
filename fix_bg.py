from PIL import Image

def fix_image(path):
    try:
        img = Image.open(path).convert("RGBA")
        datas = img.getdata()

        new_data = []
        for item in datas:
            # If the pixel is pure white or very close (only >250), make it #0A0A0A
            if item[0] > 250 and item[1] > 250 and item[2] > 250:
                new_data.append((10, 10, 10, 255))
            else:
                new_data.append(item)
        
        img.putdata(new_data)
        img.save(path, "PNG")
        print(f"Fixed {path}")
    except Exception as e:
        print(f"Error processing {path}: {e}")

fix_image('/Users/ahmed/4Me/2026 Projects/DontSkipHumanity/DSH Mobile/assets/icons/ic_logo.png')
fix_image('/Users/ahmed/4Me/2026 Projects/DontSkipHumanity/DSH Mobile/assets/icons/ic_logo_android12.png')
