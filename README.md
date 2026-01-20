# MyNotes 📝

MyNotes is a powerful, AI-enhanced note-taking application built with Flutter. It combines a beautiful pastel UI with robust cloud synchronization and smart features to help you capture and organize your thoughts effortlessly.

## ✨ Features

- **AI-Powered Insights**: Automatically generate summaries and labels for your notes, audio recordings, and **video attachments** using Groq and Cerebras AI.
- **Transcriptions**: Convert voice notes and video audio into text instantly with high accuracy (powered by Groq Whisper).
- **Video Support**: Attach videos to your notes, with built-in playback and intelligent AI summarization of the video content.
- **Unified Media Picker**: A streamlined "Gallery" option to pick both photos and videos effortlessly.
- **Cloud Sync**: Seamlessly sync notes across devices using Firebase Cloud Firestore.
- **Offline First**: Work offline with full functionality; data syncs automatically when you're back online (powered by Hive).
- **Smart Reminders**: Set time-based notifications for your notes so you never miss a task.
- **Privacy Focused**: Secure authentication and local file encryption for your sensitive media.

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (Latest Stable)
- Firebase Project Setup
- API Keys for AI Services (Groq / Gemini)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mynotes.git
   cd mynotes
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Environment**
   Duplicate `.env.example` to `.env` and add your API keys:
   ```bash
   cp .env.example .env
   ```
   *Edit `.env` with your actual keys.*

4. **Run the App**
   ```bash
   flutter run
   ```

## 🛠️ Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod
- **Local Database**: Hive
- **Cloud Backend**: Firebase (Auth, Firestore)
- **AI Integration**: Groq API (Whisper), Cerebras API (Summarization)
- **Multimedia**: FFmpeg (New Audio Kit) for video processing

## 📸 Screenshots

| Home Screen | Note Editor | AI Summary |
|:-----------:|:-----------:|:----------:|
| ![Home](docs/screenshots/home.png) | ![Editor](docs/screenshots/editor.png) | ![AI](docs/screenshots/ai.png) |

*(Note: Add your actual screenshots in `docs/screenshots/`)*

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
