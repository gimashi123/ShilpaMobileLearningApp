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