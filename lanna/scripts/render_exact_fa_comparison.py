from PIL import Image, ImageDraw, ImageFont

def render_comparison():
    img = Image.new('RGB', (800, 400), color='white')
    draw = ImageDraw.Draw(img)
    
    font_noto = ImageFont.truetype(r'D:\PROJECT_LANNA\lanna\assets\fonts\NotoSansTaiTham.ttf', 60)
    font_label = ImageFont.load_default()
    
    # 1. U+1A3A (ᨺ, ฝะ)
    draw.text((50, 50), "U+1A3A (ᨺ) Noto", fill='black', font=font_label)
    draw.text((50, 100), "\u1a3a", fill='red', font=font_noto)
    
    # 2. U+1A3B (ᨻ, พะ)
    draw.text((250, 50), "U+1A3B (ᨻ) Noto", fill='black', font=font_label)
    draw.text((250, 100), "\u1a3b", fill='red', font=font_noto)
    
    # 3. U+1A3C (ᨼ, ฟะ)
    draw.text((450, 50), "U+1A3C (ᨼ) Noto", fill='black', font=font_label)
    draw.text((450, 100), "\u1a3c", fill='red', font=font_noto)
    
    # 4. U+1A3E (ᨾ, มะ)
    draw.text((650, 50), "U+1A3E (ᨾ) Noto", fill='black', font=font_label)
    draw.text((650, 100), "\u1a3e", fill='red', font=font_noto)
    
    img.save('exact_fa_comparison.png')
    print("Saved exact_fa_comparison.png")

render_comparison()
