# Biometric Detection App

This is a simple face detection and distance estimation app using your webcam in Termux.
It uses Flask to serve a local web page where you can view the camera feed and detect faces.

## Features
- Face detection with OpenCV Haar Cascade
- Distance estimation based on face width
- Audio alert when someone is too close
- Web interface at http://localhost:5000

## Requirements
- Termux
- Python 3.10+
- Git
- FFmpeg (for playsound)

## Usage
Run the app:
```
cd ~/biometric_app
python main.py
```

Then open browser at [http://localhost:5000](http://localhost:5000)
