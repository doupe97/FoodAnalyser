import pyvista as pv

folderName = "test-17-dualCam-filtered-depth-data-heic"
filePath = "/Users/nico/Desktop/output/" + folderName + "/baked_mesh.obj"

mesh = pv.read(filePath)

volumeM3 = mesh.volume
volumeCM3 = volumeM3 * 1000000

density = 1.028 # cm3 for birne

weight = density * volumeCM3
orgWeight = 282 # gewogenes Gewicht in g

diffInPercent = ((weight * 100) / orgWeight) - 100

print("--------------------------------")
print("Waage:", orgWeight, "g")
print("Volume:", round((volumeM3 * 1000000), 8), "cm3")
print("Gewicht:", round(weight, 4), "g")
print("Abweichung:", round(diffInPercent, 4), "%")
print("--------------------------------")