#!/bin/bash

#SBATCH --job-name=ed_test        # create a short name for your job
#SBATCH --nodes=1                # node count
#SBATCH --ntasks=1               # total number of tasks across all nodes
#SBATCH --ntasks-per-node=1
#SBATCH --cpus-per-task=21       # cpu-cores per task (>1 if multi-threade>
#SBATCH --mem-per-cpu=1GB       # memory per cpu-core 
#SBATCH --time=1:00:00          # total run time limit (HH:MM:SS)
#SBATCH --mail-type=all          # send email when job ends
#SBATCH --mail-user=ed0400@princeton.edu
######## #SBATCH --exclude=della-h12n16
######## #SBATCH --constraint=cascade
######## #SBATCH --nodelist=della-h12n16

module purge
module load gurobi
module load julia/1.9.1

julia Run_oncluster.jl