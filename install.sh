# 1. Install yadm
sudo pacman -S yadm

# 2. Save n0dm script
mkdir -p ~/.local/bin
curl -o ~/.local/bin/n0dm https://raw.githubusercontent.com/noeltz/n0dm/main/n0dm
chmod +x ~/.local/bin/n0dm

# 3. Initialize
n0dm init
# Follow prompts to connect to GitHub

# 4. Test smart backup
n0dm backup "test"
n0dm sync --dry-run  # Should skip backup (no changes)
echo "# test" >> ~/.bashrc
n0dm sync --dry-run  # Should detect change, offer backup
