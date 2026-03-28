import cv2
import numpy as np
import urllib.request
import ssl

ssl._create_default_https_context = ssl._create_unverified_context

def test_logic(url, name):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        arr = np.asarray(bytearray(response.read()), dtype=np.uint8)
        bgr = cv2.imdecode(arr, -1)
        if bgr is None: return
        img_np = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        
        hsv = cv2.cvtColor(bgr, cv2.COLOR_BGR2HSV)
        h, w = img_np.shape[:2]
        total_pixels = h * w

        # Vibrant Green Check
        lower_vibrant_green = np.array([30,  50,  40])
        upper_vibrant_green = np.array([90, 255, 255])
        v_green_mask = cv2.inRange(hsv, lower_vibrant_green, upper_vibrant_green)
        v_green_ratio = cv2.countNonZero(v_green_mask) / total_pixels

        # Center Check
        center_hsv = hsv[int(h*0.25):int(h*0.75), int(w*0.25):int(w*0.75)]
        low_g = np.array([30,  60,  40]);  up_g = np.array([90, 255, 255])
        low_b = np.array([10,  70,  20]);  up_b = np.array([30, 255, 200])
        low_y = np.array([22,  60,  80]);  up_y = np.array([34, 255, 255])

        gc = cv2.countNonZero(cv2.inRange(center_hsv, low_g, up_g))
        bc = cv2.countNonZero(cv2.inRange(center_hsv, low_b, up_b))
        yc = cv2.countNonZero(cv2.inRange(center_hsv, low_y, up_y))

        center_ratio = (gc + bc + yc) / (center_hsv.shape[0] * center_hsv.shape[1])
        
        print(f"[{name}] Overall Green: {v_green_ratio:.2%}, Center Plant: {center_ratio:.2%}")
        
        # New Idea: Excess Green vs Excess Red
        # Plants have G > R and G > B. Mammals/Earth have R > G.
        r, g, b_ = cv2.split(img_np.astype(float))
        exg = (2*g - r - b_)
        avg_exg = np.mean(exg)
        print(f"[{name}] Avg Excess Green (ExG): {avg_exg:.2f}")

    except Exception as e:
        print(f"[{name}] Error: {e}")

test_logic('https://upload.wikimedia.org/wikipedia/commons/4/43/Cute_dog.jpg', 'Dog')
test_logic('https://upload.wikimedia.org/wikipedia/commons/4/4b/Grape_black_rot.jpg', 'Real Leaf (Diseased)')
test_logic('https://upload.wikimedia.org/wikipedia/commons/7/7b/Orange-Whole-%26-Split.jpg', 'Orange Fruit')
