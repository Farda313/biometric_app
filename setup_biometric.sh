#!/bin/bash
# تنظیمات اولیه
REPO_URL="https://github.com/Farda313/biometric_app.git "
EMAIL="farda8106@gmail.com"
PROJECT_DIR="$HOME/biometric_app"

echo "[+] Step 1: Installing required packages..."
pkg install python git ffmpeg curl -y

echo "[+] Step 2: Setting up project directory..."
cd "$PROJECT_DIR" || { echo "[-] Project folder not found"; exit 1; }

# نصب کتابخانه‌ها
pip install flask opencv-python playsound || pip install flask opencv-python-headless playsound

# تست وجود app.py
if [ ! -f "app.py" ]; then
    echo "[+] Creating web server file: app.py..."

    cat << 'EOL' > app.py
from flask import Flask, render_template, Response
import cv2
import numpy as np
from playsound import playsound
import os

app = Flask(__name__)

KNOWN_WIDTH = 15.0  # cm
FOCAL_LENGTH = 600  # px

def distance_to_camera(knownWidth, focalLength, perceivedWidth):
    return (knownWidth * focalLength) / perceivedWidth

face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')

def generate_frames():
    cap = cv2.VideoCapture(0)
    while True:
        success, frame = cap.read()
        if not success:
            break
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=5)

        for (x,y,w,h) in faces:
            dist = distance_to_camera(KNOWN_WIDTH, FOCAL_LENGTH, w)
            label = f"{dist:.2f} cm"
            cv2.rectangle(frame, (x,y), (x+w, y+h), (255,0,0), 2)
            cv2.putText(frame, label, (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0,255,0), 2)

            if dist < 50 and not os.path.exists("alert_played.flag"):
                try:
                    os.system("ffplay -nodisp -autoexit alert.mp3")
                    open("alert_played.flag", "w").close()
                except Exception as e:
                    print("Sound error:", e)

        ret, buffer = cv2.imencode('.jpg', frame)
        frame_bytes = buffer.tobytes()
        yield (b'--frame\r\n'
               b'Content-Type: image/jpeg\r\n\r\n' + frame_bytes + b'\r\n')

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/video_feed')
def video_feed():
    return Response(generate_frames(), mimetype='multipart/x-mixed-replace; boundary=frame')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL
fi

# تست وجود index.html
mkdir -p templates
if [ ! -f "templates/index.html" ]; then
    echo "[+] Creating HTML template..."
    cat << 'EOL' > templates/index.html
<!DOCTYPE html>
<html>
<head>
    <title>Biometric Detection</title>
    <style>
        body { font-family: Arial, sans-serif; text-align: center; }
        img { max-width: 100%; margin-top: 20px; }
    </style>
</head>
<body>
    <h1>Biometric Detection App</h1>
    <img src="/video_feed" width="640">
</body>
</html>
EOL
fi

# Git Sync
if [ ! -d ".git" ]; then
    echo "[+] Initializing Git repository..."
    git init
    git remote add origin $REPO_URL
    git config --local user.email "$EMAIL"
    git config --local user.name "Farda313"
    git add .
    git commit -m "Initial commit from Termux"
    git branch -M main
    git push -u origin main
else
    echo "[+] Git repo already exists. Pulling latest changes..."
    git pull origin main
    git add .
    git commit -m "Update biometric app $(date)"
    git push origin main
fi

# اجرای وب‌سرور
echo "[+] Starting Flask Web App on http://localhost:5000"
python app.py
