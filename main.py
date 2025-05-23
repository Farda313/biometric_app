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

# بارگذاری مدل Haar Cascade از مسیر فعلی
face_cascade = cv2.CascadeClassifier('haarcascade_frontalface_default.xml')

def generate_frames():
    while True:
        # خواندن تصویر ثابت
        frame = cv2.imread("photo.jpg")
        if frame is None:
            print("[-] Could not load image")
            break

        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        faces = face_cascade.detectMultiScale(gray, scaleFactor=1.3, minNeighbors=5)

        for (x, y, w, h) in faces:
            dist = distance_to_camera(KNOWN_WIDTH, FOCAL_LENGTH, w)
            label = f"{dist:.2f} cm"
            cv2.rectangle(frame, (x, y), (x+w, y+h), (255, 0, 0), 2)
            cv2.putText(frame, label, (x, y-10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 2)

            if dist < 50 and not os.path.exists("alert_played.flag"):
                try:
                    playsound('alert.mp3')
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
