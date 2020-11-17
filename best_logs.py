import glob
import json
import sys
import os

work_d = os.path.abspath(os.getcwd())
bad_files = os.path.join(work_d, '*_BAD')
de = glob.glob(bad_files)
for i in de:
  os.remove(bad_files)


files = os.path.join(work_d, 'logfile_*')

files_list = glob.glob(files)

data = {}
data['log'] = []
num = sys.argv[1]

file_name = 'batch_log_'+str(num)+'.json'

with open(file_name, "w") as f:
  for i in range(len(files_list)):
    with open( files_list[i] , "r") as g:
      tmp= float("inf")
      for line in g:
        r=line.split()
        if (float(r[2]) < tmp):
          tmp= float(r[2])
          best_line= line
    t = best_line.split()
    data['log'].append({
      'ID': str(t[0]),
      'CF': t[2],
      'TIME': t[4]
    })
    json.dump(data, f)
