import os
import shutil
import subprocess
import pyvista
import time
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse

# setup the fast api app
app = FastAPI()

#region Configuration

# local parameters
pathExecutable = "/Users/nico/Desktop/FoodAnalyser/02_server/ObjectCaptureApi"
pathInputFolder = "/Users/nico/Desktop/FoodAnalyser/02_server/input"
pathOutputFolder = "/Users/nico/Desktop/FoodAnalyser/02_server/output"
pathModelFile = f"{pathOutputFolder}/baked_mesh.obj"

# object capture api detail level (preview, reduced, medium, full, raw)
detailLevel = "medium" # default

# object capture api sample ordering (unordered, sequential)
sampleOrdering = "sequential" # default

# object capture api feature sensitivity (normal, high)
featureSensitivity = "normal" # default

#endregion

# endpoint for checking the servers availability
@app.get("/alive")
async def Alive():
    return { "statusCode" : 200 }

# endpoint for uploading an image
@app.post("/upload-image")
async def UploadImage(file: UploadFile = File(...)):
    try:
        # store received (uploaded) image on local disk
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
async def AnalyseObject(detailLevelOption: str, featureSensitivityOption: str):
    try:
        #region 1. Generate the 3D model by Object Capture API
        
        # set detail level parameter for object capture api
        dl = detailLevel # default = medium
        if detailLevelOption:
            dl = detailLevelOption

        # set feature sensitivity parameter for object capture api
        fs = featureSensitivity # default = normal
        if featureSensitivityOption:
            fs = featureSensitivityOption
        
        # call object capture api as command executable
        start = time.time()
        cp = subprocess.run(
            [f"{pathExecutable} {pathInputFolder} {pathOutputFolder} -d {dl} -o {sampleOrdering} -f {fs}"],
            check=True,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )
        end = time.time()
        measurementTimeInSeconds = round((end - start), 4)

        # check if generated OBJ 3D model file exists
        if os.path.exists(pathModelFile) == False:
            return {
                "statusCode" : 500,
                "errorMessage" : "Could not generate OBJ 3D model."
            }

        #endregion

        #region 2. Calculate object volume

        # calculate object volume of generated 3d model by PyVista library
        pyvistaMesh = pyvista.read(pathModelFile)
        pyvistaVolumeCM3 = round((pyvistaMesh.volume * 1000000), 4)
        
        #endregion

        return {
            "statusCode" : 200,
            "detailLevel": dl,
            "featureSensitivity": fs,
            "volumeInCM3" : pyvistaVolumeCM3,
            "measurementTimeInSeconds": measurementTimeInSeconds
        }

    except Exception as e:
        return {
            "statusCode" : 500,
            "errorMessage" : f"Could not analyse the object due to: '{e}'"
        }

# endpoint for getting the generated 3d model file
@app.get("/get-3d-model", response_class=FileResponse)
async def Get3DModel():
    try:
        # check if 3d model file exists on local disk
        if os.path.exists(pathModelFile) == False:
            return {
                "statusCode" : 500,
                "errorMessage" : "Could not find source OBJ 3D model."
            }

        return pathModelFile
    
    except Exception as e:
        return {
            "statusCode" : 500,
            "errorMessage" : f"Could not get OBJ 3D model due to: '{e}'"
        }
