# Server Documentation

### API setup python packages:
- required python version: 3.10.8
- pip3 install fastapi
- pip3 install uvicorn
- pip3 install python-multipart
- pip3 install pyvista

### Folder structure
./input = folder for storing the uploaded images
./output = folder for storing the generated 3D model

### Create virtual environment:
1. python3 -m venv ./venv
2. source ./venv/bin/activate

### Start API Server:
uvicorn server:app --reload --host 192.168.178.81 --port 8000