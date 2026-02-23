# 🤖 n0dm Development Agent Guidelines

> **Important:** This document defines development standards for the n0dm project. Follow these guidelines to maintain consistency, quality, and the project's distinctive visual identity.

---

## 📌 Repository Distinction

### ⚠️ CRITICAL: Never Confuse These Repositories

| Repository | Purpose | URL | Usage |
|------------|---------|-----|-------|
| **n0dm** (software) | The n0dm tool itself | `github.com/noeltz/n0dm` | Install script, bash code, readme |
| **n0ctachiri** (dotfiles) | Personal dotfiles managed BY n0dm | `github.com/noeltz/n0ctachiri` | Your actual config files synced via yadm |

### 🚫 What NOT to Do

```bash
# WRONG - Don't push software changes to dotfiles repo
cd ~/.local/share/yadm/repo.git
git push origin main  # This goes to n0ctachiri!

# WRONG - Don't track n0dm source in dotfiles
n0dm track ~/dev/n0dm/n0dm  # No! This is the software itself
```

### ✅ Correct Workflow

```bash
# Working on n0dm software
cd ~/dev/n0dm
git add n0dm
git commit -m "feat: added something"
git push  # Pushes to github.com/noeltz/n0dm

# Syncing dotfiles with n0dm tool
n0dm sync "Updated bashrc"  # Uses yadm, pushes to n0ctachiri
```

---

## 🔢 Versioning Scheme

### Semantic Versioning: `MAJOR.MINOR.PATCH`

```
Current: 1.2.0
Next:    1.2.1  (patch fix)
         1.3.0  (minor feature)
         2.0.0  (major breaking change)
```

### When to Increment

| Type | Version Bump | Examples |
|------|--------------|----------|
| **PATCH** (0.0.1) | Bug fixes, typos, minor improvements | Fix help output, correct typo in readme |
| **MINOR** (0.1.0) | New features, backwards compatible | Add `connect` command, new `--force` flag |
| **MAJOR** (1.0.0) | Breaking changes | Change config format, remove commands |

### How to Update Version

```bash
# 1. Edit n0dm script header (lines 4-10)
readonly N0DM_VERSION="1.2.1"

# 2. Update readme badge if major/minor
# 3. Commit with descriptive message
git commit -m "chore: bump version to 1.2.1"

# 4. Push so n0dm update works
git push
```

### Version Update Checklist

- [ ] Update `N0DM_VERSION` in `n0dm` script
- [ ] Update version badge in `readme.md` (if applicable)
- [ ] Add entry to changelog (if exists)
- [ ] Test `./n0dm version` shows correct version
- [ ] Test `./n0dm update` would detect the new version

---

## 🎨 Visual Style Guidelines

### README.md Aesthetic Principles

The n0dm readme is designed to be **visually stunning** and **highly scannable**. Follow these principles:

#### 1. Emoji-First Navigation

```markdown
## 🎯 Why n0dm?
## ✨ Features at a Glance
## 🚀 Quick Start
## 🤔 What Is n0dm?
## 📋 Command Reference
## 🤖 Automation
## ❓ FAQ
```

**Rule:** Every major section starts with a relevant emoji.

#### 2. Table-Driven Comparisons

```markdown
| Problem | n0dm Solution |
|---------|---------------|
| "I broke my config" | **Smart backups** auto-save |
| "Symlinks keep breaking" | **No symlinks!** |
```

**Rule:** Use tables for before/after, problem/solution comparisons.

#### 3. ASCII Diagrams for Workflows

```
🖥️ Laptop          ☁️ GitHub          🖥️ Desktop
┌─────────┐        ┌─────────┐        ┌─────────┐
│ ~/.bashrc│──push─►│ username/│◄─pull─│ ~/.bashrc│
└─────────┘        │ dotfiles │        └─────────┘
                   └─────────┘
```

**Rule:** Visual workflows > text descriptions.

#### 4. Callout Boxes with Emojis

```markdown
> 💡 **Tip:** Use `n0dm sync --force` for first push
> ⚠️ **Warning:** This will overwrite remote history
> 🛡️ **Safety:** Backups are created automatically
```

**Rule:** Use `> emoji **Type:** message` format for callouts.

#### 5. Badge Stack

```markdown
<p align="center">
  <img src="https://img.shields.io/badge/Arch_Linux-1793D1?style=for-the-badge&logo=arch-linux" alt="Arch">
  <img src="https://img.shields.io/badge/Bash-4EAA25?style=for-the-badge&logo=gnu-bash" alt="Bash">
</p>
```

**Rule:** Use `for-the-badge` style, center-align, 4-6 max badges.

#### 6. Code Blocks with Comments

```bash
# Initialize your dotfiles repo
n0dm init

# Track your first file
n0dm track ~/.bashrc

# Sync to GitHub
n0dm sync "Initial commit"
```

**Rule:** Always include inline comments explaining each step.

#### 7. Feature Checklists

```markdown
✅ No symlinks — files stay in their natural home
✅ Smart backups — only backup when files change
✅ Two-way sync — pull from GitHub, push your changes
```

**Rule:** Use `✅` for features, `❌` for problems solved.

---

## 🧑‍💻 User-Friendliness Guidelines

### Code Style Principles

#### 1. Clear Error Messages

```bash
# ❌ BAD
print_err "Push failed"

# ✅ GOOD
print_err "Push failed. The remote repository may not exist yet."
print_info "Create it on GitHub:"
echo "  gh repo create $repo_name --public --push"
```

**Rule:** Always tell users **what went wrong** + **how to fix it**.

#### 2. Interactive Prompts with Defaults

```bash
# ❌ BAD
read -p "Continue? " -r answer

# ✅ GOOD
read -p "Set up remote? [Y/n] " -n 1 -r confirm
# Default to 'Y' for common actions
if [[ $confirm =~ ^[Yy]$ || "$confirm" == "" ]]; then
    # proceed
fi
```

**Rule:** Use `[Y/n]` or `[y/N]` to show defaults, accept empty input.

#### 3. Progress Indicators

```bash
print_info "Creating backup..."
# do work
print_ok "Backup created: 20260223_143022_pre-sync"
```

**Rule:** Use `print_info` (➜) for actions, `print_ok` (✓) for completion.

#### 4. Non-Destructive Defaults

```bash
# Always require confirmation for destructive actions
if [[ "${N0DM_YES:-false}" != "true" ]]; then
    read -p "Proceed? [y/N] " -n 1 -r
    [[ $REPLY =~ ^[Yy]$ ]] || return 0
fi
```

**Rule:** Destructive operations need explicit confirmation unless `--yes`.

#### 5. Helpful Output

```bash
# ❌ BAD
$ n0dm status
On branch main
nothing to commit

# ✅ GOOD
$ n0dm status
=== Yadm Repository Status ===
On branch main
nothing to commit

=== N0DM Backup Status ===
  Backups stored: 3 / 10
  Retention: 30 days

=== N0DM Info ===
  Version: 1.2.0
  ⚠ No remote configured
     → Run: n0dm connect <user/repo>
```

**Rule:** Provide context + next action hints in output.

---

## 📖 Documentation Standards

### README.md Structure

```markdown
# 🎯 Title + Tagline
> One-sentence description

## Badges

## Navigation Links

## 🎯 Why/Problem-Solution Table

## ✨ Feature Checklist

## 🚀 Quick Start (copy-paste commands)

## 🤔 Explanation (plain English)

## 📋 Command Reference (tables)

## 🤖 Automation Examples

## ❓ FAQ

## 🙏 Acknowledgments
```

### Function Documentation

```bash
#--- Function Name -------------------------------------------------------------
# Brief description of what it does
#
# Arguments:
#   $1 - description
#   $2 - description
#
# Returns:
#   0 - success
#   1 - error description
#
# Side Effects:
#   Creates files in $N0DM_BACKUP_DIR
#
# Example:
#   create_backup "pre-sync"
#
#-------------------------------------------------------------------------------
function_name() {
    local arg1="$1"
    ...
}
```

---

## 🧪 Testing Guidelines

### Before Committing

```bash
# 1. Syntax check
bash -n n0dm

# 2. Test help/version
./n0dm help
./n0dm version

# 3. Test modified functionality
./n0dm status
./n0dm sync --dry-run

# 4. Check for shellcheck warnings (if available)
shellcheck n0dm
```

### Test Scenarios

| Scenario | Command | Expected |
|----------|---------|----------|
| Fresh install | `./n0dm init` | Prompts for remote |
| No remote | `./n0dm sync` | Error + hint to `connect` |
| First push | `./n0dm sync --force` | Creates upstream |
| Normal sync | `./n0dm sync "msg"` | Backup + pull + push |
| No changes | `./n0dm sync` | Skips backup |

---

## 🚀 Release Process

### Pre-Release Checklist

- [ ] All tests pass
- [ ] Version bumped in `n0dm` script
- [ ] README updated (if UI/behavior changed)
- [ ] Changelog entry added
- [ ] `./n0dm update` would detect new version
- [ ] Git history is clean and descriptive

### Commit Message Format

```
type: short description

- bullet point for notable change
- bullet point for another change

Fixes: #issue-number (if applicable)
```

**Types:**
- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation only
- `style:` Formatting, no code change
- `refactor:` Code restructuring
- `chore:` Version bump, maintenance

---

## 🔐 Security Guidelines

### Never Commit

- [ ] API keys or tokens
- [ ] `.ssh/` directory contents
- [ ] `.gnupg/` private keys
- [ ] `.env` files with secrets
- [ ] Browser cookies/sessions
- [ ] Database credentials

### .n0dmignore Must Include

```
# Security
.ssh/
.gnupg/private-keys*/
.pki/

# Browser data
.mozilla/*/sessionstore*
.google/chrome/*/Login*
```

---

## 📞 Support & Contribution

### When Users Report Issues

1. Run `n0dm doctor` (if available)
2. Check `n0dm version`
3. Review `n0dm status` output
4. Ask for error messages verbatim

### Contributing Code

1. Fork the repository
2. Create feature branch: `git checkout -b feat/your-feature`
3. Make changes following these guidelines
4. Test thoroughly
5. Submit Pull Request with clear description

---

## 🎯 Project Philosophy

> **"Dotfile management should be simple, safe, and feel like magic."**

- **Simple:** No symlinks, no complex config files
- **Safe:** Backups before changes, clear prompts
- **Magic:** `n0dm sync` just works™

When in doubt, ask: *"Would a non-technical user understand this?"*

---

<p align="center">
  <sub>Maintained with ☕ by noeltz</sub>
</p>
