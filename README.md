

# Shilpa – Inclusive Mobile Learning Application

## Project Description
Shilpa is a cross-platform mobile learning application created to support Sri Lankan primary school students in Grades 3–5 who experience visual, hearing, physical, or cognitive and learning difficulties.  
The system is designed to provide accessible, localized, and independent learning using Sinhala-language content and adaptive technology.

The application combines multiple accessibility methods such as voice interaction, sign language support, gesture-based control, and adaptive learning strategies into a single unified platform.


## Project Objective
The objective of this project is to develop one inclusive mobile learning platform that ensures fair and personalized education for students with multiple disabilities by using adaptive technologies, voice interaction, sign language, gesture control, and cognitive-friendly learning experiences.



## Project Team
- Wijesooriya C.D. – Visual Impairment Support  
- Thanthirige K.S.G.I. – Hearing Impairment Support  
- Perera G.W.R.S. – Physical Impairment Support  
- Mathota Arachchi S.S. – Cognitive and Learning Difficulties Support  

Supervisor: Prof. Nuwan Kodagoda  
Co-Supervisor: Mrs. Jenny Krishara  



## Problem Statement
Many existing educational applications are designed to support only a single disability type and often lack Sinhala or Tamil language support.  
In addition, most platforms are not aligned with the Sri Lankan primary school curriculum and do not support alternative interaction methods required by children with special educational needs.

Current solutions rarely combine voice guidance, sign language interaction, gesture-based control, adaptive difficulty adjustment, and gamified learning within one system.  
Shilpa addresses these limitations by providing a single inclusive platform that integrates these features to support independent learning.



## Functional Modules

### Visual Impairment Support
- Voice-based navigation using Text-to-Speech and Speech-to-Text  
- Spatial audio support for storytelling and lessons  
- vibration feedback  
- AI-assisted generation of Braille-ready learning materials  
- Compatibility with screen readers
- Progress tracking for teachers and parents  
- Braille-ready educational documents generated to support independent learning for visually impaired students

### Hearing Impairment Support
- Lessons delivered using Sri Lankan Sign Language 
- Pose estimation for sign recognition and feedback  
- Interactive sign imitation games 
- Animated visual lessons 
- Progress tracking for teachers and parents  

### Physical Impairment Support
- Voice commands, gaze tracking, and facial gesture-based control  
- Dwell-time activation with adjustable interaction timing  
- Safety features such as countdown indicators and stop commands  
- AI-based assistant with motivational feedback  
- Reward system to encourage engagement  
- Progress tracking for teachers and parents  

### Cognitive and Learning Difficulties Support
- Adaptive lessons based on learner ability levels  
- Gamified micro-learning activities  
- Animated emotional guidance and step-by-step support  
- Adaptive difficulty adjustment using machine learning  
- Simple, user-friendly lessons designed for students
- Progress tracking for teachers and parents  



## System Architecture

### Technologies Used
Frontend: Flutter (Dart)  
Backend: Node.js and FastAPI  
Database: MongoDB  
AI Technologies: TensorFlow Lite, MediaPipe, Hugging Face   
Design Tools: Figma, draw.io  

### Architecture Layers
1. User interaction layer for voice, sign, gesture, and touch input  
2. Application logic layer managing lessons and activities  
3. AI and accessibility layer for adaptive guidance and support  
4. Database layer for user profiles and progress data  
5. Security layer with authentication and data encryption  



## Data Collection
Field research and usability testing were carried out at:
- School for the Blind, Tangalle  
- School for the Deaf, Sitinamaluwa, Beliatta  
- National Institute of Education (NIE), Maharagama  

Data was collected through interviews and observations involving teachers, parents, and students, focusing on accessibility needs and effective learning interactions.



## Expected Outcomes
- An inclusive mobile learning application supporting multiple disability categories  
- Improved learner confidence, independence, and engagement  
- Localized AI-driven learning support  
- Enhanced inclusivity in Sri Lankan primary education  

## Installation and Setup

Clone the Repository

```bash
git clone https://github.com/gimashi123/ShilpaMobileLearningApp.git
```


## Project Setup Guidance


# Shilpa Mobile Learning App - Backend

This is the backend service for the Shilpa Mobile Learning App built with Node.js, Express, TypeScript, and MongoDB.

## Prerequisites

Before you begin, ensure you have the following installed:
- Node.js (v14 or higher)
- npm (Node Package Manager)
- MongoDB (local installation) or MongoDB Atlas account

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone https://github.com/gimashi123/ShilpaMobileLearningApp.git
   cd ShilpaMobileLearningApp/backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Environment Configuration**
   - Copy the example environment file:
     ```bash
     cp .env.example .env
     ```
   - Update the `.env` file with your configuration:
     - `PORT`: Application port (default: 3000)
     - `MONGODB_URI`: Your MongoDB connection string

4. **Development Mode**
   ```bash
   npm run dev
   ```
   This will start the server with hot-reload enabled.

5. **Production Build**
   ```bash
   npm run build   # Compile TypeScript to JavaScript
   npm start       # Start the production server
   ```

## Project Structure

```
backend/
├── src/
│   ├── config/     # Configuration files
│   ├── controllers/# Route controllers
│   ├── models/     # Database models
│   ├── routes/     # API routes
│   ├── middlewares/# Custom middleware
│   ├── utils/      # Utility functions
│   ├── types/      # TypeScript type definitions
│   └── server.ts   # Application entry point
├── .env.example    # Example environment variables
├── .gitignore      # Git ignore rules
├── package.json    # Project dependencies and scripts
├── tsconfig.json   # TypeScript configuration
└── README.md       # Project documentation
```

## Available Scripts

- `npm run dev`: Start development server with hot-reload
- `npm run build`: Build the TypeScript code
- `npm start`: Start the production server

## API Documentation

Documentation for the API endpoints will be added here as they are developed.

## Contributing

1. Create a new branch for your feature
2. Make your changes
3. Submit a pull request

## License

This project is licensed under the ISC License.

# Shilpa – Inclusive Mobile Learning Application - Frontend
# React + Vite

This template provides a minimal setup to get React working in Vite with HMR and some ESLint rules.

Currently, two official plugins are available:

- [@vitejs/plugin-react](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react) uses [Babel](https://babeljs.io/) (or [oxc](https://oxc.rs) when used in [rolldown-vite](https://vite.dev/guide/rolldown)) for Fast Refresh
- [@vitejs/plugin-react-swc](https://github.com/vitejs/vite-plugin-react/blob/main/packages/plugin-react-swc) uses [SWC](https://swc.rs/) for Fast Refresh

## React Compiler

The React Compiler is not enabled on this template because of its impact on dev & build performances. To add it, see [this documentation](https://react.dev/learn/react-compiler/installation).

## Expanding the ESLint configuration

If you are developing a production application, we recommend using TypeScript with type-aware lint rules enabled. Check out the [TS template](https://github.com/vitejs/vite/tree/main/packages/create-vite/template-react-ts) for information on how to integrate TypeScript and [`typescript-eslint`](https://typescript-eslint.io) in your project.

Please follow the instructions in the respective README files to correctly set up and run each part of the system.





