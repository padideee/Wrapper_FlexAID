import argparse
import glob
import shutil
import subprocess
import json
import pandas as pd
import math
import sys
import os


def FlexAID(protein, cleft, ligs, smiles_directory, population, generation, run, lib_path):

    cmd = ["python", "parallel_run.py", protein, cleft, ligs,
           smiles_directory, str(run), str(population), str(generation), lib_path]
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate()
    p.wait()


def analyse(iteration, cut_off):

    cmd = ["python", "best_logs.py", str(iteration)]
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    out, err = p.communicate()
    p.wait()

    file_name = 'batch_log_' + str(iteration) + '.json'

    with open(file_name) as json_file:
        data = json.load(json_file)
    df = pd.DataFrame(data)
    df = df.sort_values(by=['CF'], ignore_index=True)
    l = math.floor(len(df) * cut_off)
    df_new = df[:l, :]
    if cut_off != 1:
        work_d = os.path.abspath(os.getcwd())
        bad_files_1 = os.path.join(work_d, 'logfile_*')
        de = glob.glob(bad_files_1)
        bad_files_2 = os.path.join(work_d, '*.pdb')
        de.extend(bad_files_2)
        bad_files_3 = os.path.join(work_d, 'CONFIG*')
        de.extend(bad_files_3)
        bad_files_4 = os.path.join(work_d, 'ga_inp*')
        de.extend(bad_files_4)

        for i in de:
            os.remove(i)

    with open('lig_list_new.txt', 'w') as outfile:
        outfile.write('\n'.join(df_new['ID'].astype(str).values))

    log_name = 'top_CF_' + str(iteration) + '.txt'
    with open( log_name, 'w') as outfile:
        outfile.write('\n'.join(df_new.astype(str).values))


def main():

    parser = argparse.ArgumentParser(description="the arguments.", add_help=False)
    parser.add_argument("-p", "--protein", action="store")
    parser.add_argument("-c", "--cleft", action="store")
    parser.add_argument("-l", "--ligands_file", action="store")
    parser.add_argument("-d", "--smiles_directory", action="store")
    parser.add_argument("-a", "--lib_path", action="store")
    args = parser.parse_args()

    protein = args.protein
    cleft = args.cleft
    ligs = args.ligands_file
    smiles_directory = args.smiles_directory
    lib_path = args.lib_path

    shutil.copyfile(ligs, 'lig_list_new.txt')

    num_ligs = sum(1 for line in open(ligs))
    print(num_ligs)
    cut_off = []
    populations = []
    generations = []
    runs = []

    try:

        if 10000 < num_ligs <= 600000:
            cut_off = [1, .1, .01]
            populations = [250, 1000, 1000]
            generations = [250, 1000, 1000]
            runs = [1, 1, 10]

        elif 1000 < num_ligs <= 10000:
            cut_off = [1, .01]
            populations = [500, 1000]
            generations = [500, 1000]
            runs = [1, 10]

        elif num_ligs <= 1000:
            cut_off = [1]
            populations = [1000]
            generations = [1000]
            runs = [10]


    except:

        print(" The size of Ligand Library is not acceptable. Max size = 600'000 ")
        sys.exit(1)

    for i in range(len(cut_off)):

        FlexAID(protein, cleft, 'lig_list_new.txt', smiles_directory, populations[i], generations[i], runs[i], lib_path)
        analyse(i+1, cut_off[i])


if __name__ == '__main__':

    main()
