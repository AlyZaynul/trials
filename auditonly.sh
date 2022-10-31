apt install auditd audispd-plugins -y
systemctl --now enable auditd

printf "
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope
" >> /etc/audit/rules.d/50-scope.rules

augenrules --load


printf "
-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation
" >> /etc/audit/rules.d/50-user_emulation.rules

augenrules --load

{
SUDO_LOG_FILE=$(grep -r logfile /etc/sudoers* | sed -e 's/.*logfile=//;s/,?.*//' -e 's/"//g')
[ -n "${SUDO_LOG_FILE}" ] && printf "
-w ${SUDO_LOG_FILE} -p wa -k sudo_log_file
" >> /etc/audit/rules.d/50-sudo.rules || printf "ERROR: Variable 'SUDO_LOG_FILE_ESCAPED' is unset.\n"
}

augenrules --load


