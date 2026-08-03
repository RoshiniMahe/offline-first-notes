# offline_first

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

for server configuration 

# Mock Server Setup

This project uses **JSON Server** as a mock REST API for testing the offline-first notes application.

## Prerequisites

- Node.js installed
- npm installed

## Folder Structure

```
mockserver/
├── db.json
```

## Start the Mock Server

1. Open a terminal.
2. Navigate to the `mockserver` folder.

```bash
cd mockserver
```

3. Start the JSON Server.

```bash
npx json-server db.json
```

The server will start on:

```
http://localhost:3000
```

## API Endpoints

Get all notes

```
GET http://localhost:3000/notes
```

Get note by ID

```
GET http://localhost:3000/notes/{id}
```

Create note

```
POST http://localhost:3000/notes
```

Update note

```
PUT http://localhost:3000/notes/{id}
```

Delete note

```
DELETE http://localhost:3000/notes/{id}
```

## Stop the Server

Press:

```
Ctrl + C
```

to stop the server.
