import glob
import json
import sys
import os

de = glob.glob('*'+'_BAD')
for i in de:
  os.remove(i)

files_list = glob.glob('logfile_'+'*')

data = {}
data['log'] = []

num = sys.argv[1]

file_name = 'batch_log_'+str(num)+'.json'

with open(file_name, "w") as f:
    for i in range(len(files_list)):
        with open( files_list[i] , "r") as g:
            print(files_list[i])
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
        print(data)
    json.dump(data, f)