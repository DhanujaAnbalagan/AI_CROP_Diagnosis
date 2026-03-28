# SWE_AI_CROP_BACK Codebase Analysis

## 1. Project Overview
This is the backend for an AI-powered crop advisory system. It provides APIs for user authentication, crop management, community features, and importantly, **AI-based crop disease diagnosis** using both a custom CNN model (handled by a Python microservice) and Google's Gemini LLM.

**Tech Stack:**
- **Runtime:** Node.js
- **Framework:** Express.js
- **Database:** MongoDB (using Mongoose)
- **AI/ML:** 
    - Google Gemini (via `@google/genai`) for text advice.
    - Python (FastAPI + TensorFlow) for image classification.

---

## 2. Directory Structure & Component Breakdown

### 📂 Root Directory
- **`server.js`**: The main entry point.
    - Sets up the Express server.
    - Connects to MongoDB.
    - Configures CORS (Cross-Origin Resource Sharing).
    - Mounts all API routes to `/api/...`.
- **`package.json`**: Manages Node.js dependencies and scripts (`start`, `dev`).

### 📂 `models/` (Database Schemas)
Defines the structure of data stored in MongoDB.

| File | Purpose | Key Fields |
| :--- | :--- | :--- |
| **`User.js`** | User profile data. | `phoneNumber`, `name`, `role`, `profileImage` |
| **`AppSettings.js`** | User-specific app settings. | `language`, `audioEnabled`, `guestMode` |
| **`CropPreference.js`** | Stores which crops a user is interested in. | `selectedCrops` (Array of strings) |
| **`DiagnosisRecord.js`** | History of AI disease predictions. | `imageUrl`, `predictedDisease`, `confidenceScore` |
| **`CommunityPost.js`** | Social feed posts. | `title`, `content`, `type`, `likes`, `comments` |
| **`CalendarTask.js`** | Farming tasks/reminders. | `title`, `type` (watering, etc.), `date`, `completed` |
| **`ConsentLog.js`** | Legal/Policy consent tracking. | `agreed`, `ipAddress`, `timestamp` |

### 📂 `routes/` (API Endpoints)
Handles HTTP requests and links them to database models or services.

| File | Endpoint Base | Functionality |
| :--- | :--- | :--- |
| **`authRoutes.js`** | `/api/auth` | Login via phone number & mock OTP verification. |
| **`userRoutes.js`** | `/api/user` | Get or update user profile details. |
| **`cropAdvice.js`** | `/api` | **Core Feature:**<br>1. `/crop-advice`: Get text advice from Gemini.<br>2. `/analyze`: Upload image → CNN prediction → Gemini advice. |
| **`diagnosisRoutes.js`** | `/api/diagnosis` | Save and retrieve past disease checks. |
| **`cropRoutes.js`** | `/api/crops` | Manage user's selected crops. |
| **`communityRoutes.js`**| `/api/community`| CRUD for community posts, likes, and comments. |
| **`calendarRoutes.js`** | `/api/calendar` | Manage farming tasks/events. |
| **`settingsRoutes.js`** | `/api/settings` | Get/Set user preferences (language, audio). |
| **`consentRoutes.js`** | `/api/consent` | Log user agreement to terms. |

### 📂 `services/` (Business Logic Helper)
Contains reusable logic separating "how it works" from "how it's called".

- **`llmService.js`**: 
    - Manages the connection to **Google Gemini AI**.
    - Function `generateCropAdvice`: Constructs a prompt with crop/disease info and asks Gemini for structured advice (Cause, Symptoms, Treatment, etc.).
- **`cnnService.js`**:
    - Acts as a bridge between the Node.js backend and the Python AI service.
    - Sends image data to `http://127.0.0.1:5001/predict`.

### 📂 `ai_service/` (Python AI Microservice)
A standalone Python application that runs the Computer Vision model.

- **`app.py`**: 
    - A **FastAPI** server running on port 5001.
    - Loads a TensorFlow/Keras model (`model.weights.h5`).
    - Endpoint `/predict`: Accepts an image, validates it's a leaf, and returns the disease class & confidence.
- **`class_names.py`**: 
    - List of 38 disease classes (e.g., `Tomato___Early_blight`) corresponding to the model's output indices.
- **`model.weights.h5`**: The pre-trained Deep Learning model weights.

---

## 3. How It All Connects (The "Analyze" Flow)

1.  **User** uploads a leaf image in the frontend.
2.  **Frontend** sends POST request to Node.js backend: `/api/analyze`.
3.  **`cropAdvice.js`** (Route) receives the image.
4.  It calls **`cnnService.js`**, which forwards the image to the **Python `ai_service`** (port 5001).
5.  **`app.py`** predicts the disease (e.g., "Tomato Early Blight") and returns it.
6.  **`cropAdvice.js`** takes this prediction and calls **`llmService.js`**.
7.  **`llmService.js`** asks **Gemini** for detailed advice/treatment for "Tomato Early Blight".
8.  **Node.js Backend** combines the prediction + advice and returns full JSON to the frontend.
