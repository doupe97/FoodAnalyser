import os
import csv
import shutil
import subprocess
import pyvista
import trimesh
import boto3
import requests
from fastapi import FastAPI, UploadFile, File
from fastapi.responses import FileResponse

# setup the fast api app
app = FastAPI()

#region Configuration

# aws rekognition api parameters
awsApiService = "rekognition"
awsApiRegion = "eu-central-1"
awsApiAccessKeyId = "AKIAYTMG3KDEHZLDPCOP"
awsApiSecretKey = "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"

# local parameters
pathExecutable = "/Users/nico/Desktop/FoodAnalyser/02_server/ObjectCaptureApi"
pathInputFolder = "/Users/nico/Desktop/FoodAnalyser/02_server/input"
pathOutputFolder = "/Users/nico/Desktop/FoodAnalyser/02_server/output"
pathModelFile = f"{pathOutputFolder}/baked_mesh.obj"
densityCsvFilePath = "/Users/nico/Desktop/FoodAnalyser/02_server/density.csv"

# object capture api detail level (preview, reduced, medium, full, raw)
detailLevel = "medium"

# object capture api sample ordering (unordered, sequential)
sampleOrdering = "sequential"

# object capture api feature sensitivity (normal, high)
featureSensitivity = "normal"

# search api url for food data central
foodDataCentralApiUrl = "https://api.nal.usda.gov/fdc/v1/foods/search"

# food data central request
foodDataCentralApiParams = {
    "dataType" : "SR Legacy",
    "pageSize" : "1",
    "pageNumber" : "1",
    "sortBy" : "dataType.keyword",
    "sortOrder" : "asc",
    "api_key" : "AIU73hcuBV0CSApK6s3qkzgV3tWfYjUaHFuH1cig"
}

# list with all relevant nutrients
relevantNutrients = [
    "protein",
    "sugars",
    "water",
    "energy",
    "carbohydrate",
    "total lipid (fat)",
    "magnesium",
    "calcium",
    "zinc",
    "sodium",
    "alcohol",
    "vitamin a",
    "vitamin b-12",
    "vitamin c",
    "vitamin d",
    "vitamin e",
    "vitamin k",
    "sucrose",
    "glucose",
    "maltose",
    "copper",
    "iron",
    "phosphorusv",
    "selenium",
    "caffeine"
]

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
async def AnalyseObject():
    try:
        #region 1. Identify object by image classification API
        
        dirList = os.listdir(pathInputFolder)
        if len(dirList) == 0:
            return {
                "statusCode" : 500,
                "errorMessage" : "No input images could be found. Please upload input images first."
            }
        
        # create path variables
        pathInputImageHeic = f"{pathInputFolder}/{dirList[0]}"
        pathInputImageJpg = pathInputImageHeic.replace(".heic", ".jpg")

        # convert image format from .heic to .jpg
        cp = subprocess.run(
            [f"magick {pathInputImageHeic} {pathInputImageJpg}"],
            check=True,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        # check if jpg image file exists
        if os.path.exists(pathInputImageJpg) == False:
            return {
                "statusCode" : 500,
                "errorMessage" : "Could not convert image from .heic to .jpg format."
            }

        # create aws rekognition api client
        client = boto3.client(
            awsApiService,
            aws_access_key_id = awsApiAccessKeyId,
            aws_secret_access_key = awsApiSecretKey,
            region_name = awsApiRegion)

        # get raw image file bytes
        with open(pathInputImageJpg, "rb") as src_image:
            src_bytes = src_image.read()

        # call aws rekognition api
        response = client.detect_labels(
            Image={'Bytes': src_bytes},
            MaxLabels=10,
            MinConfidence = 90)

        # transform api response and get object label
        objectLabel = ""
        objectLabelConfidence = 0.0
        for label in response['Labels']:
            if not label['Instances']:
                continue
            else:
                objectLabel = label['Name'].lower()
                objectLabelConfidence = label['Confidence']
                break

        if objectLabel == "":
            return {
                "statusCode" : 500,
                "errorMessage" : f"Could not identify the input object."
            }

        #endregion

        #region 2. Get density information about the object

        # get density information from .csv file and create dictionary
        densityDict = {}
        with open(densityCsvFilePath) as csvFile:
            reader = csv.reader(csvFile)
            for row in reader:
                arr = row[0].split(";")
                densityDict[arr[0]] = arr[1]

        # extract density information for given object from dictionary
        objectDensity = float(densityDict[objectLabel])

        if not objectDensity:
            return {
                "statusCode" : 500,
                "errorMessage" : "Could not get object density information."
            }

        #endregion

        #region 3. Generate the 3D model by Object Capture API
        
        # call object capture api as command executable
        cp = subprocess.run(
            [f"{pathExecutable} {pathInputFolder} {pathOutputFolder} -d {detailLevel} -o {sampleOrdering} -f {featureSensitivity}"],
            check=True,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE
        )

        # check if generated OBJ 3D model file exists
        if os.path.exists(pathModelFile) == False:
            return {
                "statusCode" : 500,
                "errorMessage" : "Could not generate OBJ 3D model."
            }

        #endregion

        #region 4. Calculate object volume and weight

        # calculate object volume of generated 3d model by PyVista library
        pyvistaMesh = pyvista.read(pathModelFile)
        pyvistaVolumeCM3 = pyvistaMesh.volume * 1000000
        
        # calculate object volume of generated 3d model by Trimesh library
        trimeshMesh = trimesh.load(pathModelFile)
        trimeshVolumeCM3 = trimeshMesh.volume * 1000000
        
        # calculate object weight
        # formula: m = p * V
        pyvistaWeightInGrams = objectDensity * pyvistaVolumeCM3
        trimeshWeightInGrams = objectDensity * trimeshVolumeCM3

        #endregion

        #region 5. Fetch food nutrient information by FoodData Central API

        # call the FoodData Central api
        foodDataCentralApiParams["query"] = objectLabel.lower().strip()
        response = requests.get(url = foodDataCentralApiUrl, params = foodDataCentralApiParams)
        data = response.json()

        if not data:
            print("No data found")

        # extract raw food nutrients from api response
        nutrientsRaw = data["foods"][0]["foodNutrients"]
        nutrients = {}

        for nutrient in nutrientsRaw:
            nutrientName = nutrient["nutrientName"].lower()
            if any(substring in nutrientName for substring in relevantNutrients):
                #region transform nutrient information

                if nutrientName == "total lipid (fat)":
                    nutrientName = "fat"

                nutrientName = nutrientName.split(", ", 1)[0]
                nutrientName = nutrientName.split(" (", 1)[0]

                # differ nutrient energy values
                if nutrient["nutrientId"] == 1062: 
                    nutrientName = "kJ"
                elif nutrient["nutrientId"] == 1008:
                    nutrientName = "kcal"

                if nutrientName == "carbohydrate":
                    nutrientName = "carbohydrates"

                # remove spaces in nutrient name
                arrSpace = nutrientName.split(" ", 1)
                if len(arrSpace) == 2:
                    nutrientName = arrSpace[0] + arrSpace[1].upper()

                # remove hyphen in nutrient name
                nutrientName = nutrientName.replace("-", "")

                #endregion

                # calculate real object nutrients by object weight
                nutrients[nutrientName] = (pyvistaWeightInGrams * nutrient["value"]) / 100

        if not nutrients or len(nutrients) == 0:
            return {
                "statusCode" : 500,
                "errorMessage" : "Could not fetch nutrient information from FoodData Central API."
            }
        
        #endregion

        #region 6. Delete uploaded images and generated 3D model

        # delete the server api input folder
        #for file in os.listdir(pathInputFolder):
        #    os.remove(os.path.join(pathInputFolder, file))

        # delete the server api output folder
        #for file in os.listdir(pathOutputFolder):
        #    os.remove(os.path.join(pathOutputFolder, file))

        #endregion

        return {
            "statusCode" : 200,
            "label" : objectLabel,
            "confidence" : objectLabelConfidence,
            "density" : objectDensity,
            "pyvista": {
                "usedLibrary" : "PyVista v0.36.1",
                "volumeInCM3" : pyvistaVolumeCM3,
                "weightInGrams" : pyvistaWeightInGrams
            },
            "trimesh": {
                "usedLibrary" : "Trimesh v3.16.2",
                "volumeInCM3" : trimeshVolumeCM3,
                "weightInGrams" : trimeshWeightInGrams
            },
            "nutrients": nutrients
        }

    except Exception as e:
        return {
            "statusCode" : 500,
            "errorMessage" : f"Could not analyse the input object due to: '{e}'"
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
