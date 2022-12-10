import os
import csv
import subprocess
import requests
import json

pathOutputFolder = "/Users/nico/Desktop/FoodAnalyser/02_server/output"
pathObjModelFile = f"{pathOutputFolder}/baked_mesh.obj"
pathUsdzModelFile = pathObjModelFile.replace(".obj", ".usdz")

pathUsdzConverter = "/Applications/usdpython/usdzconvert/usdzconvert"
exportCommands = "export PATH=$PATH:/Applications/usdpython/USD:$PATH:/Applications/usdpython/usdzconvert;export PYTHONPATH=$PYTHONPATH:/Applications/usdpython/USD/lib/python"

cmd = f"{pathUsdzConverter} {pathObjModelFile}"

# convert 3d model from .obj to .usdz format via usdzconvert tool
cp = subprocess.run(
    [f"{exportCommands}; {cmd}"],
    check=True,
    shell=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE
)

# check if generated 3D model file exists
exists = os.path.exists(pathUsdzModelFile)