"""Generate the branded QR asset; keep the QR's full white quiet zone intact."""
from pathlib import Path
import qrcode
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1] / 'public'
URL = 'https://pmo-territorial-colombia.vercel.app/'
NAVY = '#152b43'
ORANGE = '#e1a365'
image = Image.new('RGB', (1200, 1540), NAVY)
draw = ImageDraw.Draw(image)
regular = 'C:/Windows/Fonts/arial.ttf'
bold = 'C:/Windows/Fonts/arialbd.ttf'
font = lambda size: ImageFont.truetype(regular, size)
heavy = lambda size: ImageFont.truetype(bold, size)

# Logo: bars form a project portfolio growing towards a shared objective.
draw.rounded_rectangle((72, 66, 164, 158), radius=16, fill='#274765')
for x, top in ((91, 119), (112, 101), (133, 84)):
    draw.rectangle((x, top, x + 13, 141), fill=ORANGE)
draw.line((88, 146, 151, 146), fill='#ffffff', width=3)
draw.text((185, 82), 'PMO', font=heavy(52), fill='white')
draw.text((187, 138), 'TERRITORIAL', font=heavy(21), fill='#afc0d1', spacing=4)
draw.text((72, 235), 'Conectemos necesidades', font=heavy(57), fill='white')
draw.text((72, 306), 'con proyectos.', font=heavy(57), fill=ORANGE)
draw.text((74, 397), 'Escanea y comparte tu necesidad empresarial', font=font(30), fill='#d2dce6')

qr = qrcode.QRCode(error_correction=qrcode.constants.ERROR_CORRECT_Q, box_size=22, border=4)
qr.add_data(URL)
qr.make(fit=True)
code = qr.make_image(fill_color=NAVY, back_color='white').convert('RGB')
qr_size = 814
code = code.resize((qr_size, qr_size), Image.Resampling.NEAREST)
x = (1200 - qr_size) // 2
y = 480
draw.rounded_rectangle((x - 17, y - 17, x + qr_size + 17, y + qr_size + 17), radius=25, fill='white')
image.paste(code, (x, y))

draw.text((600, 1364), 'UNA INICIATIVA PARA COLOMBIA', font=heavy(25), fill=ORANGE, anchor='mm')
draw.text((600, 1420), 'pmo-territorial-colombia.vercel.app', font=font(27), fill='#d2dce6', anchor='mm')
image.save(ROOT / 'qr-pmo.png', optimize=True)
