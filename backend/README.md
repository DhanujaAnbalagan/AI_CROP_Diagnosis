# 🌱 SWE_AI_CROP_BACK — AI Crop Disease Detection Backend

Backend services for the SWE_AI_CROP system.  
This repository handles **CNN inference, AI advisory generation, and API orchestration** between the frontend and machine learning services.

---

## 🚜 Overview

This backend powers the AI pipeline that allows farmers to:

- Upload crop leaf images
- Detect plant diseases using a CNN model
- Receive AI-generated treatment advice
- Get structured responses for frontend display

The system integrates **Computer Vision + Generative AI** into a single API.

---

## 🧠 System Pipeline

Upload image  
↓  
Node Backend API  
↓  
FastAPI CNN Service  
↓  
Disease prediction  
↓  
Gemini AI Advisory  
↓  
Single JSON response


----

## 🧰 Tech Stack

### Backend API
- Node.js
- Express.js
- Axios
- Multer

### AI Inference Service
- FastAPI
- TensorFlow / Keras
- Pillow
- NumPy

### AI Advisory
- Google Gemini API (@google/genai)

---

<img width="308" height="465" alt="image" src="https://github.com/user-attachments/assets/df9300cc-ba68-4360-84be-c5ee92411ff9" />





---

## ✨ Features

### CNN Disease Detection
- MobileNetV2 transfer learning model
- PlantVillage dataset
- 38 disease classes supported
- Image preprocessing pipeline

---

### Leaf Validation

Rejects invalid uploads such as:
- Humans
- Objects
- Non-plant images

Response example:

```json
{
  "success": false,
  "message": "Uploaded image does not appear to be a plant leaf"
}
```
## 🤖 AI Advisory System

Uses Gemini AI to generate:

- Cause
- Symptoms
- Immediate action
- Chemical treatment
- Organic treatment
- Prevention

---

## 🔌 API Endpoints

### Test Backend
GET /api/test

### Crop Disease Detection + Advice
POST /api/crop-advice

Form-data:
file → image

---

## 📦 Example Response

```json
{
  "success": true,
  "disease": "Leaf_Mold",
  "confidence": 0.99,
  "advice": {
    "cause": "...",
    "symptoms": "...",
    "immediate": "...",
    "chemical": "...",
    "organic": "...",
    "prevention": "..."
  }
}
```


## ▶️ Running Locally

Follow these steps to run the backend and CNN inference service.

---

### 1. Install Node dependencies

From the project root:

```bash
npm install

cd ai_service
pip install -r requirements.txt
python -m uvicorn app:app --reload --port 5001

Uvicorn running on http://127.0.0.1:5001

Expected response:

{
  "success": true,
  "disease": "Leaf_Mold",
  "confidence": 0.99,
  "advice": { ... }
}
```

---

## 🔮 Future Improvements

- Dockerized deployment
- Offline CNN inference support
- Confidence calibration for predictions
- Model quantization for mobile devices
- Region-specific crop advisory tuning
- Logging and monitoring
- Model retraining pipeline

---

## 🤝 Contributing

This project is part of the SWE AI Crop system.  
Contributions, suggestions, and improvements are welcome.

To contribute:

1. Fork the repository
2. Create a new branch
3. Make changes
4. Submit a pull request

---

## 👨‍💻 Contributors

| Name | Role |
|------|------|
| Dhanuja | Backend Engineer |
| Bhuvaneshwari | DevOps Engineer |
| Ramaroshinee | Full Stack Developer |
| Akshith | Frontend Developer |
| Saketh | Testing Engineer |

---

## 🌾 Vision

Build an AI-powered agriculture assistant that helps farmers detect crop diseases early and receive clear, actionable treatment guidance.


