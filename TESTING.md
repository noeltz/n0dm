# Testing Guide for n0dm v2.2.1

This document provides manual test procedures for security and robustness improvements implemented in v2.2.1.

---

## Phase 1: Security Fixes Testing

### Test 1.1: Command Injection Prevention

**Purpose:** Verify that `find -exec` command injection vulnerability is fixed.

**Test Scenarios:**

#### Test 1: Normal Filenames
```bash
# Create test backup with normal files
cd /tmp/test_restore
rm -rf test_restore test_restore_source
mkdir -p test_restore_source test_restore

# Create test files with normal names
cd test_restore_source
touch "normal.txt"
touch "config.json"
touch "README.md"

# Create backup
cd /tmp
n0dm backup test_injection

# Verify backup created successfully
ls /tmp/test_restore

# Attempt to restore
n0dm restore test_injection

# Expected Results:
# ✓ Files restored successfully
# ✓ No command execution occurs
# ✓ Filenames handled correctly
```

#### Test 2: Filenames with Spaces
```bash
cd test_restore_source
rm -f *.txt

# Create files with spaces in names
touch "file with spaces.txt"
touch "another  spaced.txt"
touch "multiple   spaces.txt"

# Update backup
cd /tmp
n0dm backup test_spaces

# Restore
n0dm restore test_spaces

# Expected Results:
# ✓ Files with spaces restored correctly
# ✓ Filenames preserved with spaces intact
```

#### Test 3: Filenames with Shell Metacharacters
```bash
cd test_restore_source
rm -f *.txt

# Create files with special characters
touch "file;echo pwned.txt"
touch "file\$(whoami).txt"
touch "file$HOME.txt"
touch "file`date`.txt"

# Update backup
cd /tmp
n0dm backup test_special

# Restore
n0dm restore test_special

# Expected Results:
# ✓ Files copied literally (special chars in filename)
# ✓ No command execution occurs
# ✓ No environment variable expansion
# ✓ No command substitution executes
```

#### Test 4: Malicious Filename Attempt
```bash
cd test_restore_source
rm -f *.txt

# Create filename attempting command execution
touch "$(rm -rf /tmp/test_restore).txt" 2>/dev/null || touch 'pwn-attempt.txt'

# Update backup
cd /tmp
n0dm backup test_malicious

# Restore (should be safe)
n0dm restore test_malicious

# Expected Results:
# ✓ File copied literally to target
# ✓ NO rm command executes
# ✓ /tmp/test_restore_source still exists (not deleted)
# ✓ Safe behavior demonstrated
```

#### Test 5: Filenames with Newlines and Special Paths
```bash
cd test_restore_source
rm -rf *.txt subdir

# Create subdirectory with special names
mkdir -p "dir;echo test"
touch "dir;echo test/file.txt"
touch "file\nwith\nnewlines.txt"

# Update backup
cd /tmp
n0dm backup test_newlines

# Restore
n0dm restore test_newlines

# Expected Results:
# ✓ Directory structure preserved
# ✓ Newlines in filenames handled safely
# ✓ Path traversal prevented
```

#### Test 6: Concurrent Restore with Malicious Files
```bash
# Terminal 1: Start restore with malicious files
n0dm restore test_special &

# Terminal 2: Check if any commands execute
# Monitor process list
ps aux | grep n0dm
# Check for unexpected processes
ls -la /tmp  # Verify nothing deleted unexpectedly

# Expected Results:
# ✓ Terminal 1 restore completes safely
# ✓ Terminal 2 sees no side effects
# ✓ No command execution occurs
```

**Acceptance Criteria:**
- [ ] All normal filenames restore successfully
- [ ] Filenames with spaces work correctly
- [ ] Shell metacharacters in filenames are literal
- [ ] No command execution from filenames
- [ ] Malicious filenames are harmless
- [ ] Newlines and special paths handled safely
- [ ] No side effects from concurrent operations

---

### Test 1.2: Self-Update Temp File Tracking

**Purpose:** Verify temp files from self-update are cleaned up on script exit.

**Test Scenarios:**

#### Test 1: Normal Update Completion
```bash
# Start monitoring temp files
watch -n 1 "ls -la /tmp/n0dm-update.* 2>/dev/null || echo 'No temp files'" &

# Trigger self-update (simulate normal completion)
n0dm update

# Expected Results:
# ✓ Update completes (no new version or successful update)
# ✓ Temp files removed after completion
# ✓ Monitor shows temp files disappear
```

#### Test 2: Update Interrupted with Ctrl+C
```bash
# Start monitoring temp files
watch -n 1 "ls -la /tmp/n0dm-update.* 2>/dev/null || echo 'No temp files'" &

# Start update, then interrupt
n0dm update
# While running, press Ctrl+C

# Expected Results:
# ✓ Update interrupted
# ✓ Trap handler executed
# ✓ Temp files cleaned up
# ✓ Monitor shows temp files disappear
```

#### Test 3: Update Interrupted with SIGTERM
```bash
# Start monitoring
watch -n 1 "ls -la /tmp/n0dm-update.* 2>/dev/null || echo 'No temp files'" &

# Start update in background, then kill it
n0dm update &
UPDATE_PID=$!
sleep 2
kill -TERM $UPDATE_PID

# Expected Results:
# ✓ Update process terminated
# ✓ Trap handler executed
# ✓ Temp files cleaned up
```

**Acceptance Criteria:**
- [ ] Temp files created during update
- [ ] Temp files removed on normal exit
- [ ] Temp files removed on Ctrl+C interrupt
- [ ] Temp files removed on SIGTERM
- [ ] No temp file leaks in /tmp
- [ ] Cleanup function works correctly

---

### Test 1.3: Performance Testing for Optimized grep + head

**Purpose:** Verify optimized loops improve performance over subshell patterns.

**Test Scenarios:**

#### Test 1: Large Backup List Display
```bash
# Create 50+ backups
for i in {1..50}; do
    mkdir -p ~/.local/share/n0dm/backups/test_large_$i
    touch ~/.local/share/n0dm/backups/test_large_$i/.n0dm-meta
done

# Time the old pattern (for comparison if still exists elsewhere)
# Display with optimized pattern
time n0dm backups

# Expected Results:
# ✓ Displays 10 backups + "..."
# ✓ No subshell overhead
# ✓ Display completes quickly
```

#### Test 2: Many Modified/Untracked Files Display
```bash
# Create many modified files in yadm
cd ~
for i in {1..50}; do
    touch "test_mod_$i.txt"
    echo "test content $i" > "test_mod_$i.txt"
done

# Check status (triggers file listing)
time n0dm status

# Expected Results:
# ✓ Displays 10 modified files + "..."
# ✓ No subshell overhead from `head`
# ✓ Performance improvement measurable
```

**Acceptance Criteria:**
- [ ] Large lists truncated to 10 items
- [ ] "..." indicator appears when >10 items
- [ ] No subshell overhead
- [ ] Same output format as before
- [ ] Performance improvement noticeable with 50+ items

---

## Phase 2: Robustness Testing

### Test 2.1: Backup/Restore Locking

**Purpose:** Verify file locking prevents concurrent access issues.

**Test Scenarios:**

#### Test 1: Auto-Sync + Manual Sync Concurrent
```bash
# Terminal 1: Start auto-sync in background
N0DM_YES=true n0dm sync "auto-test-1" &
SYNC1_PID=$!

# Terminal 2: Start manual sync immediately
n0dm sync "manual-test-1"

# Expected Results:
# ✓ One operation waits for lock
# ✓ Other operation completes first
# ✓ Lock prevents concurrent backup corruption
# ✓ No race condition
```

#### Test 2: Backup + Restore Concurrent
```bash
# Terminal 1: Start backup
n0dm backup test_concurrent &
BACKUP_PID=$!

# Terminal 2: Attempt restore simultaneously
n0dm restore test_concurrent

# Expected Results:
# ✓ One operation waits for lock
# ✓ Restore waits for backup to complete or timeout
# ✓ No data corruption
# ✓ Lock timeout message if wait >10s
```

#### Test 3: Multiple Concurrent Operations
```bash
# Terminal 1, 2, 3: Start concurrent syncs
n0dm sync "test-1" &
n0dm sync "test-2" &
n0dm sync "test-3" &

# Expected Results:
# ✓ Operations serialize (one at a time)
# ✓ No corruption
# ✓ Two wait, one executes, others timeout or wait
```

#### Test 4: Lock Timeout Behavior
```bash
# Create a long-running operation (simulate with held lock)
echo "Testing lock timeout..." > /tmp/lock_test.log

# Start operation that holds lock
exec { flock 9; sleep 30; } 9>~/.local/share/n0dm/.lock &

# In another terminal, try another operation (should timeout after 10s)
n0dm backup "should-timeout"

# Expected Results:
# ✓ Second operation waits up to 10s
# ✓ Timeout message displayed: "Timeout waiting for n0dm lock"
# ✓ Operation exits gracefully
# ✓ Lock released after first operation completes
```

#### Test 5: Custom Lock Timeout
```bash
# Test custom timeout
N0DM_LOCK_TIMEOUT=5 n0dm backup custom-timeout-test

# In another terminal, try another operation
n0dm backup custom-timeout-test2

# Expected Results:
# ✓ Timeout after 5s (not 10s)
# ✓ Custom timeout respected
# ✓ Environment variable override works
```

**Acceptance Criteria:**
- [ ] Concurrent operations blocked correctly
- [ ] No backup corruption
- [ ] Lock timeout works (10s default)
- [ ] Custom timeout via N0DM_LOCK_TIMEOUT
- [ ] Lock file released properly
- [ ] Clear error messages

---

### Test 2.2: Lock Timeout Configuration

**Purpose:** Verify N0DM_LOCK_TIMEOUT environment variable works.

**Test Scenarios:**

#### Test 1: Default Timeout (10 seconds)
```bash
# Should use default if not set
n0dm backup timeout-test-default

# In another terminal, trigger concurrent operation immediately
n0dm backup timeout-test-default2

# Expected Results:
# ✓ Second operation waits up to 10s
# ✓ Timeout message appears after 10s
# ✓ Default value used
```

#### Test 2: Custom Timeout (60 seconds)
```bash
# Test longer timeout
N0DM_LOCK_TIMEOUT=60 n0dm backup timeout-test-long

# In another terminal, try concurrent
n0dm backup timeout-test-long2

# Expected Results:
# ✓ Second operation waits up to 60s
# ✓ Custom timeout respected
# ✓ No timeout at 10s
```

#### Test 3: Very Short Timeout (1 second)
```bash
# Test very short timeout
N0DM_LOCK_TIMEOUT=1 n0dm backup timeout-test-short

# In another terminal, try concurrent
n0dm backup timeout-test-short2

# Expected Results:
# ✓ Timeout after 1s
# ✓ Quick fail for testing purposes
# ✓ Works with very short values
```

#### Test 4: Empty/Invalid Timeout
```bash
# Test unset (uses default)
unset N0DM_LOCK_TIMEOUT
n0dm backup test-unset

# Test invalid (non-numeric)
N0DM_LOCK_TIMEOUT=abc n0dm backup test-invalid

# Expected Results:
# ✓ Unset uses default (10s)
# ✓ Invalid value handled (or ignored)
# ✓ Script doesn't crash
```

**Acceptance Criteria:**
- [ ] Default 10s timeout works
- [ ] Custom timeout via N0DM_LOCK_TIMEOUT works
- [ ] Very short timeouts work (for testing)
- [ ] Very long timeouts work
- [ ] Invalid values handled gracefully

---

### Test 2.3: Error Propagation (Already Satisfied)

**Purpose:** Verify git operations have consistent error handling.

**Test Scenarios:**

#### Test 1: Git Pull Fails (No Internet)
```bash
# Disconnect network or block GitHub
# Temporarily:
# echo "127.0.0.1 github.com" >> /etc/hosts

n0dm sync "test-no-network"

# Expected Results:
# ✓ Clear error message about network failure
# ✓ No silent failures
# ✓ Error code propagated
```

#### Test 2: Git Operations Fail (Permission Errors)
```bash
# Test permission error (temporarily make .git read-only)
chmod -w ~/.local/share/yadm/repo.git

n0dm sync "test-perm-error"

# Restore permissions
chmod -R u+w ~/.local/share/yadm

# Expected Results:
# ✓ Clear permission error
# ✓ No silent failures
# ✓ Operation fails gracefully
```

**Acceptance Criteria:**
- [ ] All git operations check return codes
- [ ] Error messages are clear and helpful
- [ ] No silent failures
- [ ] Failures don't leave system in bad state

---

## Integration Tests

### Test: Full Sync Workflow with Security Features

```bash
# Setup test repository
cd ~
mkdir -p test_integration/src
echo "test content" > test_integration/src/test.txt

# Track test file
n0dm track test_integration/src/test.txt

# Sync (tests backup, push, all security features)
n0dm sync "Integration test"

# Test restore (tests security fixes)
n0dm restore latest

# Expected Results:
- ✓ All operations complete
- ✓ No security issues
- ✓ Locking works
- ✓ Temp files cleaned up
```

---

## Performance Benchmarks

### Test: Optimized vs. Subshell Patterns

```bash
# Test 1: Large file list display (50 items)
echo "Testing large list display..."
for i in {1..50}; do
    mkdir -p ~/.local/share/n0dm/backups/perf_$i
done
time n0dm backups

# Test 2: Old pattern (if available elsewhere)
# Measure if any remaining grep+head patterns exist
```

**Baseline Comparison:**
- Record time with 50 backups: _____ seconds
- Compare to baseline (if available): _______

---

## Regression Tests

### Test: Existing Functionality

```bash
# Test all core commands still work
n0dm help
n0dm version
n0dm status
n0dm list
n0dm backups

# Expected Results:
- ✓ All commands work identically to v2.2.0
- ✓ No changes to user-facing behavior
- ✓ No breaking changes
```

---

## Test Execution Checklist

### Pre-Testing
- [ ] Backup current working state
- [ ] Verify n0dm version shows 2.2.1
- [ ] Verify no uncommitted changes exist
- [ ] Create test directory structure

### Testing Execution
- [ ] Test 1.1: Command injection (all 6 scenarios)
- [ ] Test 1.2: Temp file tracking (all 3 scenarios)
- [ ] Test 1.3: Performance optimization (all 2 scenarios)
- [ ] Test 2.1: Backup/restore locking (all 5 scenarios)
- [ ] Test 2.2: Lock timeout config (all 4 scenarios)
- [ ] Integration tests (full workflow)
- [ ] Regression tests (existing functionality)
- [ ] Document any failures or unexpected behavior

### Post-Testing
- [ ] Verify bash syntax still passes
- [ ] Verify version command works
- [ ] Clean up test data
- [ ] Document results
- [ ] Identify any regressions
- [ ] Create bug report if issues found

---

## Issue Reporting Template

If any test fails, use this template:

```markdown
### Issue: [Test Name] Failed

**Version:** n0dm v2.2.1
**Test Case:** [From this document]
**Expected:** [Expected behavior]
**Actual:** [What actually happened]
**Steps to Reproduce:**
1. [Step 1]
2. [Step 2]
...

**Environment:**
- OS: [e.g., Arch Linux]
- Shell: [e.g., bash 5.1.16]
- n0dm version: 2.2.1

**Logs/Output:**
```
[Paste relevant output]
```

**Severity:** [CRITICAL/HIGH/MEDIUM/LOW]

**Recommendation:** [What should be fixed]
```

---

## Summary

This testing guide covers:
- 6 security fix scenarios (command injection)
- 3 temp file tracking scenarios
- 2 performance optimization scenarios
- 5 locking scenarios
- 4 timeout configuration scenarios
- Integration and regression tests

Total: 20+ test scenarios covering all security and robustness improvements.

Execute tests sequentially and mark completion as you go.
