import os
import shutil
import subprocess
import pyvista
import time
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse

# setup the fast api app
app = FastAPI()

# configuration variables
pathExecutable = "/Users/nico/Desktop/FoodAnalyser/02_server/ObjectCaptureApi"
pathInputFolder = "/Users/nico/Desktop/FoodAnalyser/02_server/input"
pathOutputFolder = "/Users/nico/Desktop/FoodAnalyser/02_server/output"
pathModelFile = f"{pathOutputFolder}/baked_mesh.obj"

# endpoint for checking the servers availability
@app.get("/alive")
async def Alive():
    return { "statusCode" : 200 }

# endpoint for uploading an image
@app.post("/upload-image")
async def UploadImage(file: UploadFile = File(...)):
    try:
        # store received / uploaded image on local disk
        with open(f'{pathInputFolder}/{file.filename}', 'wb') as buffer:
            shutil.copyfileobj(file.file, buffer)
        return { "statusCode" : 200 }
        
    except Exception as e:
        return {
            "statusCode" : 500,
            "errorMessage" : f"Could not upload image due to: '{e}'"
        }

# endpoint for analysing an object
@app.get("/analyse-object")
async def AnalyseObject(dl: str, fs: str):
    try:
        # count uploaded input images
        numberInputImages = -1
        for _, _, files in os.walk(pathInputFolder):
            numberInputImages += len(files)

        # call object capture api as command executable
        start = time.time()
        cp = subprocess.run(
            [f"{pathExecutable} {pathInputFolder} {pathOutputFolder} -o sequential -d {dl} -f {fs}"],
            check=True,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        end = time.time()
        measurementTimeInSec = round((end - start), 4)

        # check if generated 3d model file exists (.obj)
        if os.path.exists(pathModelFile) == False:
            return {
                "statusCode" : 500,
                "errorMessage" : "Could not generate OBJ 3D model."
            }
        
        # calculate object volume from 3d model with PyVista
        mesh = pyvista.read(pathModelFile)
        volumeInCm3 = round((mesh.volume * 1000000), 4)

        # return measurement result
        return {
            "statusCode" : 200,
            "detailLevel": dl,
            "featureSensitivity": fs,
            "volumeInCm3" : volumeInCm3,
            "measurementTimeInSec": measurementTimeInSec,
            "numberInputImages": numberInputImages
        }

    except Exception as e:
        return {
            "statusCode" : 500,
            "errorMessage" : f"Could not analyse the object due to: '{e}'"
        }

# endpoint for fetching the generated 3d model file
@app.get("/get-3d-model", response_class=FileResponse)
async def Get3DModel():
    # check if 3d model file exists on local disk
    if os.path.exists(pathModelFile) == False:
        return {
            "statusCode" : 404,
            "errorMessage" : "The 3D model file does not exist."
        }

    return pathModelFile