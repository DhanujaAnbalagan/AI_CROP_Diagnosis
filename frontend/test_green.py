import cv2
import numpy as np
import urllib.request
import ssl

ssl._create_default_https_context = ssl._create_unverified_context

def test_image(url, name):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        arr = np.asarray(bytearray(response.read()), dtype=np.uint8)
        bgr = cv2.imdecode(arr, -1)
        if bgr is None: return
        img_np = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        
        h, w = img_np.shape[:2]
        center = img_np[int(h*0.25):int(h*0.75), int(w*0.25):int(w*0.75)]
        
        def ratios(arr):
            b = cv2.cvtColor(arr, cv2.COLOR_RGB2BGR)
            hsv = cv2.cvtColor(b, cv2.COLOR_BGR2HSV)
            green = cv2.inRange(hsv, np.array([35, 40, 40]), np.array([85, 255, 255]))
            brown = cv2.inRange(hsv, np.array([10, 50, 20]), np.array([30, 255, 200]))
            yellow = cv2.inRange(hsv, np.array([22, 40, 80]), np.array([34, 255, 255]))
            tot = arr.shape[0] * arr.shape[1]
            return cv2.countNonZero(green)/tot, cv2.countNonZero(brown)/tot, cv2.countNonZero(yellow)/tot
            
        gf, bf, yf = ratios(img_np)
        gc, bc, yc = ratios(center)
        print(f"[{name}] Full: G={gf:.2f}, B={bf:.2f}, Y={yf:.2f} | Center: G={gc:.2f}, B={bc:.2f}, Y={yc:.2f}")
    except Exception as e:
        print(f"[{name}] Error: {e}")

test_image('https://upload.wikimedia.org/wikipedia/commons/4/43/Cute_dog.jpg', 'Dog')
test_image('https://cdn.pixabay.com/photo/2012/04/18/13/21/leaf-37006_960_720.png', 'Cartoon')
