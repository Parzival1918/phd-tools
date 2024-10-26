# env vars
export TERM=xterm-color
export LS_COLORS='rs=0:di=01;34:ln=01;36:mh=00:pi=40;33'
export PS1='\e[33;1m\u@\h: \e[31m\W\e[0m\$ '
export DAYFOLDER=/research/GMDayGroup/daygroup/pjr1u24

# aliases
alias myquota="mmlsquota iridisfs:home iridisfs:scratch"
alias submit="sbatch job_submit.sh"
alias dayfolder="cd $DAYFOLDER"
alias scratch="cd /scratch/$USER"
alias ls="ls --color=always"
alias ".."="cd .."
alias ll="ls -l"
alias q="squeue -u $USER"
alias when="squeue -u $USER --start"
alias watchq='
while true ; do
  clear # to clear the screen
  squeue -u pjr1u24
  sleep 5
done
'