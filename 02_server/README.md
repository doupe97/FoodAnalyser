# FoodAnalyser Server API Documentation
- Required Python Version: 3.10.8

### Folder structure
/input = folder for storing the uploaded images
/output = folder for storing the generated 3D models

### Create virtual environment:
1. python3 -m venv ./venv
2. source ./venv/bin/activate

### API setup python packages:
- pip3 install --upgrade pip
- pip3 install fastapi
- pip3 install uvicorn
- pip3 install python-multipart
- pip3 install -Iv pyvista==0.36.1
- pip3 install pymeshfix

### Start API Server:
uvicorn server:app --reload --host 192.168.178.81 --port 8000

### Object Capture API
- Creates .obj + texture files:
- ./Desktop/AppleObjectCaptureApi Desktop/input Desktop/output -o sequential -d medium -f normal

- Convert .obj to .usdz:
- export PATH=$PATH:/Applications/usdpython/USD:$PATH:/Applications/usdpython/usdzconvert;
- export PYTHONPATH=$PYTHONPATH:/Applications/usdpython/USD/lib/python;
- /Applications/usdpython/usdzconvert/usdzconvert /Users/nico/Desktop/FoodAnalyser/02_server/output/baked_mesh.obj
