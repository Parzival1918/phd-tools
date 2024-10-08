function cancel {
   item_count=$(squeue -u $USER --format="%.15i %.8j %.2t" -h | wc -l)
   if (( item_count == 0 )); then
           tput setaf 3; tput bold; printf "No PENDING or RUNNING jobs\n"; tput sgr0; return 1
   fi

   # Get IDs and names of all jobs running and queuing     
   data_col=$(squeue -u $USER --format="%.15i %.8j %.2t" -h | awk '{print $1}')
   read -a ids_arr <<< $data_col

   data_col=$(squeue -u $USER --format="%.15i %.8j %.2t" -h | awk '{print $2}')
   read -a names_arr <<< $data_col


   # printe the id-name of each job
   tput smul; tput bold; printf "%10s %25s\n" "ID" "NAME     "; tput sgr0; tput rmul;
   for (( i=0; i<${#names_arr[@]}; i++ )); do
           printf "%3s %10s %20s\n" $i ${ids_arr[$i]} ${names_arr[$i]}
   done

   printf "Insert index of job: "; read job_indx

   re='^[0-9]+$'
   if ! [[ $job_indx =~ $re ]] ; then
           tput setaf 1; tput bold; printf "ERROR: Not a number or positive integer\n"; tput sgr0; return 1
   fi

   # Check that the idx is in range [0,n]
   if [ "$job_indx" -ge "${#ids_arr[@]}" ]; then
           tput setaf 1; tput bold; printf "ERROR: Index out of bounds\n"; tput sgr0; return 1
   fi

   printf "running: "; tput bold; tput setaf 3; printf "scancel ${ids_arr[$job_indx]}\n"; tput sgr0
   scancel ${ids_arr[$job_indx]}
}