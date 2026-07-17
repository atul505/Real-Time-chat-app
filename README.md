# Real-Time Chat Application

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-F2F4F9?style=flat&logo=spring-boot)
![Flutter](https://img.shields.io/badge/Flutter-02569B?style=flat&logo=flutter&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-316192?style=flat&logo=postgresql&logoColor=white)

A full-stack, real-time chat application built with **Spring Boot** on the backend and **Flutter** for the mobile client. It features real-time messaging via WebSockets, secure JWT authentication, and media sharing using Cloudinary.

## 🚀 Features

- **Real-Time Messaging**: Instant message delivery using WebSockets and the STOMP protocol.
- **Secure Authentication**: User registration and login secured with JSON Web Tokens (JWT).
- **Media Sharing**: Upload and share images and files effortlessly using Cloudinary integration.
- **Modern UI/UX**: Beautiful, responsive Flutter UI featuring Google Fonts (Inter), an emoji picker, and optimized image caching.
- **Robust Backend**: Built on Spring Boot with PostgreSQL (configured for Neon DB) for reliable data persistence.

## 🛠️ Technology Stack

### Backend (`/backend_api`)
- **Framework**: Spring Boot
- **Language**: Java 17
- **Database**: PostgreSQL (Spring Data JPA / Hibernate)
- **Security**: Spring Security, JJWT
- **Real-Time**: Spring WebSockets (STOMP)
- **Cloud Storage**: Cloudinary API
- **Build Tool**: Maven

### Mobile App (`/mobile_app`)
- **Framework**: Flutter
- **Language**: Dart
- **Networking**: `http`, `stomp_dart_client`
- **Local Storage**: `flutter_secure_storage`, `shared_preferences`
- **UI & Assets**: `emoji_picker_flutter`, `image_picker`, `file_picker`, `google_fonts`, `cached_network_image`

---

## 📋 Prerequisites

Before you begin, ensure you have met the following requirements:
* **Java Development Kit (JDK)**: Version 17 or higher.
* **Maven**: For building the Spring Boot backend.
* **Flutter SDK**: Version 3.11.1 or higher.
* **Database**: A PostgreSQL instance (local or hosted, e.g., Neon DB).
* **Cloudinary**: An account and API credentials for file uploads.

---

## ⚙️ Backend Setup (`/backend_api`)

1. **Navigate to the backend directory:**
   ```bash
   cd backend_api
   ```

2. **Configure Environment Variables:**
   Create a `.env` file in the root of the `backend_api` directory (or configure via your deployment platform) and add the following variables:
   ```env
   PORT=8080
   DB_PASSWORD=your_postgresql_password
   JWT_SECRET=your_super_secret_jwt_key
   JWT_EXPIRATION=86400000
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_API_KEY=your_api_key
   CLOUDINARY_API_SECRET=your_api_secret
   ```
   *(Note: The database URL is configured in `application.properties`. Update it if you are using a local PostgreSQL instance instead of Neon DB).*

3. **Build and Run the Application:**
   Using Maven wrapper:
   ```bash
   # Windows
   mvnw.cmd spring-boot:run

   # macOS/Linux
   ./mvnw spring-boot:run
   ```
   The backend will start on `http://localhost:8080`.

---

##📱 Mobile App Setup (`/mobile_app`)

1. **Navigate to the mobile app directory:**
   ```bash
   cd mobile_app
   ```

2. **Install Flutter Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoints:**
   Ensure that the mobile app points to your locally running backend (e.g., `http://10.0.2.2:8080` for Android emulator, or your machine's local IP for physical devices). Update the relevant constants in your Dart code.

4. **Run the App:**
   ```bash
   flutter run
   ```

---
