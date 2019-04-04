# This script is used to calibrate satellite images from Sentinel 2 using sen2cor.
# It supports multiple cores, but parallel processing can be turned off.
# Set the correct settings and paths.

import os
import time
import subprocess

# Settings
rootdir = 'C:/Images'
pathProcessor = 'C:/Users/Documents/Sen2Cor-02.05.05-win64/L2A_Process.bat'
pathConfig = 'C:/Users/Documents/sen2cor/2.5/cfg/L2A_GIPP.xml'
level = 2 # of the directory hierarchy
parallel = True
cores = 3

# Listing folders at specified level 
dir_listCopy = []
for root, dirs, files in os.walk(rootdir):
    current_level = root.count(os.path.sep)
    if current_level == level:
        dir_listCopy.append(root)

# Scenes level 1C selection
dir_list = []
for dirPath in dir_listCopy:
    dirName = dirPath.split(os.sep)
    if dirName[level][8:10]=='1C':
        dir_list.append(dirPath)

#print(dir_list)
#print('\n')
#print('Number of scenes: ' + str(len(dir_list)))

# Processing by one core
if parallel == False:
    i = 1
    for scene in dir_list:
        print('Processing scene no. ' + str(i) + ' out of ' + str(len(dir_list)))
        scene = scene.replace("/", "\\")
        print(scene)
        print("\n")
        subprocess.call('{} "{}" --GIP_L2A {}'.format(
            pathProcessor,
            scene,
            pathConfig
            ), shell=True)
        i=i+1
# Processing by multi cores
elif parallel == True and cores > 1 and isinstance(cores, int):
    dirCount = len(dir_list)
    child_processes = []
    for i in range(min(cores, len(dir_list))):
      print('Processing scene no. ' + str(i+1) + ' out of ' + str(dirCount))
      p = subprocess.Popen('{} "{}" --GIP_L2A {}'.format(
        pathProcessor,
        dir_list.pop(),
        pathConfig
        ), shell=True)
      child_processes.append(p) 
     
    while(len(dir_list) > 0):
      availableCpuIdx = -1
      for idx in range(len(child_processes)):
        if child_processes[idx].poll() is not None:
          availableCpuIdx = idx
     
        if(availableCpuIdx < 0):
          time.sleep(10)       
        else:
          print('Processing scene no. ' + str(i) + ' out of ' + str(dirCount))
          child_processes[availableCpuIdx] = subprocess.Popen('{} "{}" --GIP_L2A {}'.format(
            pathProcessor,
            dir_list.pop(),
            pathConfig
            ), shell=True) 
     
    for cp in child_processes:
      cp.wait()
else:
    print('Incorrect number of cores')
    
