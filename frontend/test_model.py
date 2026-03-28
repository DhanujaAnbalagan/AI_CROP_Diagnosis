import tensorflow as tf
import numpy as np
from PIL import Image
import urllib.request
import ssl
import cv2

ssl._create_default_https_context = ssl._create_unverified_context

IMG_SIZE = 224
NUM_CLASSES = 38

data_augmentation = tf.keras.Sequential([
    tf.keras.layers.RandomFlip("horizontal"),
    tf.keras.layers.RandomRotation(0.1),
])
normalization = tf.keras.layers.Rescaling(1./127.5, offset=-1)
base_model = tf.keras.applications.MobileNetV2(
    input_shape=(IMG_SIZE, IMG_SIZE, 3),
    include_top=False,
    weights=None,
)
inputs = tf.keras.Input(shape=(IMG_SIZE, IMG_SIZE, 3))
x = data_augmentation(inputs)
x = normalization(x)
x = base_model(x, training=False)
x = tf.keras.layers.GlobalAveragePooling2D()(x)
x = tf.keras.layers.Dropout(0.3)(x)
outputs = tf.keras.layers.Dense(NUM_CLASSES, activation="softmax")(x)

general_model = tf.keras.Model(inputs=inputs, outputs=outputs)
general_model.load_weights("d:/SWE_AI_CROP_BACK/ai_service/model.weights.h5")

def get_prediction(url, name):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        response = urllib.request.urlopen(req)
        arr = np.asarray(bytearray(response.read()), dtype=np.uint8)
        bgr = cv2.imdecode(arr, -1)
        if bgr is None: return
        img_np = cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)
        
        img = Image.fromarray(img_np).resize((IMG_SIZE, IMG_SIZE))
        img_batch = np.expand_dims(np.array(img), axis=0)
        
        pred = general_model.predict(img_batch, verbose=0)[0]
        class_index = int(np.argmax(pred))
        confidence = float(np.max(pred))
        print(f"[{name}] Index={class_index}, Conf={confidence:.4f}")
    except Exception as e:
        print(f"[{name}] Error: {e}")

get_prediction('https://upload.wikimedia.org/wikipedia/commons/4/43/Cute_dog.jpg', 'Dog')
get_prediction('https://upload.wikimedia.org/wikipedia/commons/7/7b/Orange-Whole-%26-Split.jpg', 'Orange fruit')
