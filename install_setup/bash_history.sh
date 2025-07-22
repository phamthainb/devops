echo '# === Unlimited Bash History with Timestamp ===' >> ~/.bashrc
echo 'export HISTSIZE=' >> ~/.bashrc
echo 'export HISTFILESIZE=' >> ~/.bashrc
echo 'export HISTTIMEFORMAT="%F %T "' >> ~/.bashrc
echo 'export HISTCONTROL=ignoredups:ignorespace' >> ~/.bashrc
echo 'export PROMPT_COMMAND="history -a; history -n"' >> ~/.bashrc
echo 'shopt -s histappend' >> ~/.bashrc
echo '# =============================================' >> ~/.bashrc
source ~/.bashrc
