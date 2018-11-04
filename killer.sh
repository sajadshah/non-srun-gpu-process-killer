#!/usr/bin/env bash

dir='~'
#log_file=$dir/killer.log
log_file=/dev/stdout

function log {
    printf "[$(date --rfc-3339=seconds)]: $*\n" >> $log_file
}

log "==========================="
log "Running non-srun gpu process killer"

nvidia_log=`nvidia-smi -q -d PIDS`
log $nvidia_log

gpu_pids=`echo $nvidia_log | grep -Poi 'process id[^0-9]*\K([0-9]+)' | sort -u`
log "[nvidia] PIDS using gpu : " $gpu_pids

slurm_job_ids=`squeue -h -o %i`
slurm_pids=''

for jid in $slurm_job_ids; do
    jid_pids=`sstat -a -j $jid -o Pids | sed 's/[^0-9]*//g' | egrep '^[0-9]+$'`
    if [ ! -z $jid_pids ]; then
        slurm_pids="$slurm_pids $jid_pids"
    fi
    log "[slurm] pids of job $jid : " $jid_pids
done;
log "[slurm] pids registered in slurm (running with srun): " $slurm_pids

processes_to_be_killed=''
for pid in $gpu_pids; do
    is_in_slurm=`echo $slurm_pids | grep $pid`
    if [ -z "$is_in_slurm" ]; then
        log "$pid is not ok, information of process: \n\t"`ps -fp $pid`
    else
        log "$pid is ok"
    fi
done
