from multiprocessing import Pool
import subprocess
import shlex
import sys
import os.path


def execute(command_string, working_directory=None, capture_output=True):

    assert isinstance(command_string, str)
    commands_list = shlex.split(command_string)
    if capture_output:
        return subprocess.run(commands_list, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=working_directory)
    else:
        return subprocess.run(commands_list, cwd=working_directory)


def simulate(n_processors=40):

    all_commands = []
    protein = sys.argv[1]
    cleft = sys.argv[2]
    ligs = sys.argv[3]
    smiles_directory = sys.argv[4]
    run = sys.argv[5]
    population = sys.argv[6]
    generation = sys.argv[7]
    lib_path = sys.argv[8]

    with open(ligs) as f:
        for line in f:
            tmp = line.rstrip()
            l = os.path.join(smiles_directory, tmp)
            all_commands.append("perl utility.pl -t {} -l {} -c {} -b {} -p {} -g {} -a {}"
                                .format(protein, l, cleft, run, population, generation, lib_path))

    p = Pool(n_processors)
    results = p.map(execute, all_commands)
    results = [x.stdout.decode('utf-8').strip() for x in results]

    return results


if __name__ == "__main__":

    simulate()
