# Installation & Permissions Guide

A step-by-step walkthrough for getting everything compiled and running.

---

## Step 1: Check your file structure

All four core files need to be in the **same directory**:

- `ceyro_kit.c` — the kernel module
- `hide.c` — the user-space filter
- `Makefile` — the build script
- `setup_and_launch.sh` — the setup script

If any of these are missing, the build will fail.

---

## Step 2: Make the script executable

Freshly created `.sh` files aren't executable by default on Linux. If you try running it without this step you'll get a `Permission denied` error.

```bash
cd /path/to/your/project
chmod +x setup_and_launch.sh
```

---

## Step 3: Run it as root

The script needs root because it installs packages, copies files into `/usr/local/lib/`, and loads a kernel module. None of that works without elevated privileges.

```bash
sudo ./setup_and_launch.sh
```

Enter your password when prompted. The script will handle everything else — installing headers, compiling the code, and activating the hooks.

---

## Step 4: Test the hiding

Once the setup is done, verify the user-space hiding is actually working:

```bash
touch normal_file.txt
touch ceyro_testfile.txt
ls -la
find . -name "*ceyro*"
```

`normal_file.txt` shows up as expected. `ceyro_testfile.txt` is on disk but invisible — `ls`, `find` and similar tools won't see it as long as the hook is active.

---

## Step 5: Clean up (important!)

The `LD_PRELOAD` entry in `/etc/ld.so.preload` is persistent — it survives reboots. When you're done testing, run these commands to fully remove everything:

```bash
# 1. Unload the kernel module
sudo rmmod ceyro_kit

# 2. Remove the global preload hook
sudo sed -i '\/usr\/local\/lib\/hide.so/d' /etc/ld.so.preload

# 3. Delete the shared library from disk
sudo rm -f /usr/local/lib/hide.so

# 4. Clean up build artifacts
make clean
```

After that your system is back to its original state.
