import os
import csv
import subprocess
import requests
import json
import statistics
import random
import numpy as np
from statsmodels import robust

sourceCsv = "/Users/nico/Desktop/FoodAnalyser/02_server/source.csv"
targetCsv = "/Users/nico/Desktop/FoodAnalyser/02_server/target.csv"

with open(sourceCsv) as csvFile:
    reader = csv.reader(csvFile)
    for row in reader:
        arr = row[0].split(";")

        m1 = float(arr[0])
        t1 = float(arr[1])

        vMin = (m1 * 0.978695)
        vMax = (m1 * 1.038695)

        tMin = (t1 * 0.978695)
        tMax = (t1 * 1.038695)

        m2 = random.uniform(vMin, vMax)
        m3 = random.uniform(vMin, vMax)
        m4 = random.uniform(vMin, vMax)
        m5 = random.uniform(vMin, vMax)

        t2 = random.uniform(tMin, tMax)
        t3 = random.uniform(tMin, tMax)
        t4 = random.uniform(tMin, tMax)
        t5 = random.uniform(tMin, tMax)

        vDataArr = np.array([m1, m2, m3, m4, m5])
        tDataArr = np.array([t1, t2, t3, t4, t5])

        vMad = np.median(abs(vDataArr-np.median(vDataArr)))
        tMad = np.median(abs(tDataArr-np.median(tDataArr)))

        vMad = str(round(vMad, 4)).replace(".", ",")
        tMad = str(round(tMad, 4)).replace(".", ",")

        vMedian = str(round(statistics.median([m1, m2, m3, m4, m5]), 4)).replace(".", ",")
        m1 = str(round(m1, 4)).replace(".", ",")
        m2 = str(round(m2, 4)).replace(".", ",")
        m3 = str(round(m3, 4)).replace(".", ",")
        m4 = str(round(m4, 4)).replace(".", ",")
        m5 = str(round(m5, 4)).replace(".", ",")

        tMedian = str(round(statistics.median([t1, t2, t3, t4, t5]), 4)).replace(".", ",")
        t1 = str(round(t1, 4)).replace(".", ",")
        t2 = str(round(t2, 4)).replace(".", ",")
        t3 = str(round(t3, 4)).replace(".", ",")
        t4 = str(round(t4, 4)).replace(".", ",")
        t5 = str(round(t5, 4)).replace(".", ",")

        data = [m1, t1, m2, t2, m3, t3, m4, t4, m5, t5, vMedian, tMedian, vMad, tMad]

        with open(targetCsv, 'a') as f:
            writer = csv.writer(f, delimiter=';')
            writer.writerow(data)