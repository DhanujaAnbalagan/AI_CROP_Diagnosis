# 🌱 AI_CROP_Diagnosis

**AI-Powered Crop Disease Detection & Advisory System**

---

## 🚜 Overview

AI_CROP_Diagnosis is an intelligent agriculture assistant that enables farmers to detect crop diseases from leaf images and receive actionable treatment recommendations.

The system integrates:

* 📱 Flutter Mobile Application
* 🌐 Web Interface (optional support)
* 🧠 Deep Learning Models (CNN-based)
* ⚡ Backend APIs for inference and advisory

---

## 🎯 Features

* 🌿 Crop disease detection from leaf images
* 💊 Treatment and advisory suggestions
* 🌍 Multilingual-ready interface
* 📸 Image upload and camera capture support
* ⚡ Fast backend inference
* 🔌 Modular frontend–backend architecture

---

## 🧰 Tech Stack

### Frontend (Mobile & Web)

* Flutter (Android, iOS, Web)
* Dart
* UI/UX components

### Backend

* FastAPI / Node.js (hybrid backend structure)
* REST API architecture

### AI / ML

* TensorFlow / Keras
* CNN-based models (EfficientNet / custom)
* Multiple crop-specific models:

🌿 14 Plant Species

🍎 Apple
🫐 Blueberry
🍒 Cherry
🌽 Corn (Maize)
🍇 Grape
🍊 Orange
🍑 Peach
🌶️ Pepper (Bell)
🥔 Potato
🍓 Strawberry
🍅 Tomato
🫘 Soybean
🎃 Squash
🍏 Raspberry

---

## 🏗️ Project Structure

```
AI_CROP_Diagnosis/
│
├── frontend/        # Flutter application
│   ├── lib/
│   ├── android/
│   ├── ios/
│   └── ...
│
├── backend/         # Backend + AI services
│   ├── ai_service/  # Model inference & logic
│   ├── routes/      # API routes
│   ├── services/    # Business logic
│   ├── models/      # Model handling
│   └── ...
│
└── README.md
```

---

## 🔄 System Architecture

```
User (Farmer)
     ↓
Frontend (Flutter App)
     ↓
Backend API
     ↓
AI Model Inference (.h5)
     ↓
Prediction + Advisory
     ↓
Frontend Display
```

---

## ▶️ Running the Project

### 🔹 Backend Setup

```bash
cd backend
pip install fastapi uvicorn tensorflow pillow numpy
python -m uvicorn ai_service.app:app --reload
```

Access API docs:

```
http://127.0.0.1:8000/docs
```

---

### 🔹 Frontend Setup (Flutter)

```bash
cd frontend
flutter pub get
flutter run
```

---


## 🧪 Model Details

* Dataset: PlantVillage
* Framework: TensorFlow / Keras
* Format: `.h5` models
* Multiple crop-specific trained models

---

## ⚠️ Notes

* Large model files (.h5) may increase repo size
* Backend must be running before using frontend
* Ensure correct image preprocessing for accurate predictions

----

## 🌾 Vision

To build an accessible AI-powered agriculture assistant that helps farmers detect crop diseases early and take effective action.

---

## 🚀 Future Improvements

* Real-time inference optimization
* Advanced advisory system (AI-based recommendations)
* Offline model support for rural usage



---
