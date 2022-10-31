cmd1=$(apt install auditd audispd-plugins -y)
cmd2=$(systemctl --now enable auditd)


cmd3=$(printf "
-w /etc/sudoers -p wa -k scope
-w /etc/sudoers.d -p wa -k scope
" >> /etc/audit/rules.d/50-scope.rules)

cmd4=$(augenrules --load)


cmd5=$(printf "
-a always,exit -F arch=b32 -C euid!=uid -F auid!=unset -S execve -k user_emulation
" >> /etc/audit/rules.d/50-user_emulation.rules)

cmd6=$(augenrules --load)

cmd7=$({
SUDO_LOG_FILE=$(grep -r logfile /etc/sudoers* | sed -e 's/.*logfile=//;s/,?.*//' -e 's/"//g')
[ -n "${SUDO_LOG_FILE}" ] && printf "
-w ${SUDO_LOG_FILE} -p wa -k sudo_log_file
" >> /etc/audit/rules.d/50-sudo.rules || printf "ERROR: Variable 'SUDO_LOG_FILE_ESCAPED' is unset.\n"
})

cmd8=$(augenrules --load)

cmd9=$(
printf "
-a always,exit -F arch=b32 -S adjtimex,settimeofday,clock_settime -k timechange
-w /etc/localtime -p wa -k time-change
" >> /etc/audit/rules.d/50-time-change.rules)


cmd10=$(augenrules --load)


 cmd11=$({
 UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
 AUDIT_RULE_FILE="/etc/audit/rules.d/50-privileged.rules"
 NEW_DATA=()
 for PARTITION in $(findmnt -n -l -k -it $(awk '/nodev/ { print $2 }' /proc/filesystems | paste -sd,) | grep -Pv "noexec|nosuid" | awk '{print $1}'); do
 readarray -t DATA < <(find "${PARTITION}" -xdev -perm /6000 -type f | awk -v UID_MIN=${UID_MIN} '{print "-a always,exit -F path=" $1 " -F perm=x -F auid>="UID_MIN" -F$
 for ENTRY in "${DATA[@]}"; do
 NEW_DATA+=("${ENTRY}")
 done
 done
 readarray &> /dev/null -t OLD_DATA < "${AUDIT_RULE_FILE}"
 COMBINED_DATA=( "${OLD_DATA[@]}" "${NEW_DATA[@]}" )
 printf '%s\n' "${COMBINED_DATA[@]}" | sort -u > "${AUDIT_RULE_FILE}"
})

cmd12=$(augenrules --load)

cmd13=$(printf "
-w /etc/group -p wa -k identity
-w /etc/passwd -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/security/opasswd -p wa -k identity
" >> /etc/audit/rules.d/50-identity.rules )

cmd14=$(augenrules --load)

cmd15=$({
UID_MIN=$(awk '/^\s*UID_MIN/{print $2}' /etc/login.defs)
[ -n "${UID_MIN}" ] && printf "
-a always,exit -F arch=b32 -S chmod,fchmod,fchmodat -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S lchown,fchown,chown,fchownat -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod
-a always,exit -F arch=b32 -S setxattr,lsetxattr,fsetxattr,removexattr,lremovexattr,fremovexattr -F auid>=${UID_MIN} -F auid!=unset -F key=perm_mod
" >> /etc/audit/rules.d/50-perm_mod.rules
})

cmd16=$(augenrules --load)

