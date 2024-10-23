#!/bin/bash


# Define variables
PROJECT_NAME="godmode"
API_KEY="your_openai_api_key_here"  # Replace with your actual OpenAI API key
DOCKERFILE_CONTENT=$(cat <<'EOF'
# Base image
FROM python:3.9-slim

# Set environment variables
ENV PYTHONUNBUFFERED 1

# Create and set working directory
WORKDIR /app

# Copy the requirements file
COPY requirements.txt /app/

# Install dependencies
RUN pip install --upgrade pip && pip install -r requirements.txt

# Copy the application code
COPY . /app/

# Expose port 5000
EXPOSE 5000

# Run the application
CMD ["python", "app.py"]
EOF
)

REQUIREMENTS_CONTENT=$(cat <<'EOF'
Flask==2.0.2
openai==0.10.0
EOF
)

APP_PY_CONTENT=$(cat <<'EOF'
from flask import Flask, render_template, request, jsonify
import openai

app = Flask(__name__)

# Set your OpenAI API key
openai.api_key = "$OPENAI_API_KEY"

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/ask', methods=['POST'])
def ask():
    data = request.json
    prompt = data.get('prompt', '')

    # Call OpenAI GPT-3 API
    response = openai.Completion.create(
        engine="text-davinci-003",
        prompt=prompt,
        max_tokens=100
    )

    return jsonify({'response': response.choices[0].text.strip()})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOF
)

INDEX_HTML_CONTENT=$(cat <<'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Godmode AI Interface</title>
</head>
<body>
    <h1>Godmode AI Interface</h1>
    <textarea id="prompt" placeholder="Enter your question..." rows="4" cols="50"></textarea><br>
    <button onclick="askAI()">Ask AI</button>
    <h2>Response:</h2>
    <pre id="response"></pre>

    <script>
        function askAI() {
            const prompt = document.getElementById("prompt").value;
            fetch("/ask", {
                method: "POST",
                headers: {
                    "Content-Type": "application/json"
                },
                body: JSON.stringify({ prompt })
            })
            .then(response => response.json())
            .then(data => {
                document.getElementById("response").textContent = data.response;
            });
        }
    </script>
</body>
</html>
EOF
)

DOCKER_COMPOSE_CONTENT=$(cat <<EOF
version: '3'

services:
  godmode:
    build: ./containers
    ports:
      - "5000:5000"
    volumes:
      - ./web:/app/templates
    environment:
      - OPENAI_API_KEY=$API_KEY
EOF
)

# Step 1: Create Project Directory
echo "Creating project directories..."
mkdir -p $PROJECT_NAME/containers $PROJECT_NAME/config $PROJECT_NAME/web

# Step 2: Create Dockerfile
echo "Writing Dockerfile..."
echo "$DOCKERFILE_CONTENT" > $PROJECT_NAME/containers/Dockerfile

# Step 3: Create requirements.txt
echo "Writing requirements.txt..."
echo "$REQUIREMENTS_CONTENT" > $PROJECT_NAME/containers/requirements.txt

# Step 4: Create app.py (backend logic)
echo "Writing app.py..."
echo "$APP_PY_CONTENT" | sed "s/\$OPENAI_API_KEY/$API_KEY/" > $PROJECT_NAME/containers/app.py

# Step 5: Create index.html (frontend UI)
echo "Writing index.html..."
echo "$INDEX_HTML_CONTENT" > $PROJECT_NAME/web/index.html

# Step 6: Create docker-compose.yml
echo "Writing docker-compose.yml..."
echo "$DOCKER_COMPOSE_CONTENT" > $PROJECT_NAME/docker-compose.yml

# Step 7: Navigate to project directory
cd $PROJECT_NAME

# Step 8: Build Docker container
echo "Building Docker container..."
docker-compose build

# Step 9: Start Docker container
echo "Starting Docker container..."
docker-compose up -d

# Step 10: Inform the user
echo "Godmode setup is complete. Access the web interface at http://localhost:5000"