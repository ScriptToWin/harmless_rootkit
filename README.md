# Ceyro Unified Kit — Hybrid Simulation Environment

This project combines a **Linux Kernel Module (LKM)** running in kernel space (Ring 0) with a **shared library (`hide.so`)** for user-space hiding via `LD_PRELOAD` (Ring 3). It's meant for learning and experimenting with privilege boundaries and AV evasion techniques — in a safe, isolated environment.

> [!WARNING]
> Only run this inside a dedicated virtual machine. Kernel modifications can destabilize your system, and a global preload hook affects every single process on the OS. Don't do this on your main machine.

---

## What's in here

- `ceyro_kit.c` — The kernel module source. Prints an ASCII banner to dmesg when loaded.
- `hide.c` — A `readdir` hook that hides files containing "ceyro" from tools like `ls` and `find`.
- `Makefile` — Builds both the `.ko` kernel module and the `hide.so` shared library.
- `setup_and_launch.sh` — Automated setup script. Handles everything from installing headers to loading the module.

---

## Getting started

### 1. Make the script executable
```bash
chmod +x setup_and_launch.sh
```

### 2. Run it as root
```bash
sudo ./setup_and_launch.sh
```

The script will install kernel headers, compile everything, set up the LD_PRELOAD hook and load the kernel module automatically.

### 3. Check that it's working

**Kernel space:** After loading, the ASCII banner should show up in dmesg:
```bash
dmesg | tail -n 20
```

**User space hiding:** Create a couple of test files and see what happens:
```bash
touch normal_file.txt
touch ceyro_secret.txt
ls -la
```
`normal_file.txt` shows up. `ceyro_secret.txt` is physically on disk but completely invisible to `ls`, `find` and similar tools.

---

## Uninstalling

Since `hide.so` gets written to `/etc/ld.so.preload`, it survives reboots. Make sure to clean up after you're done:

```bash
# Unload the kernel module
sudo rmmod ceyro_kit

# Remove the preload hook
sudo sed -i '\/usr\/local\/lib\/hide.so/d' /etc/ld.so.preload
sudo rm -f /usr/local/lib/hide.so

# Clean up build artifacts
make clean
```

---

## How would this get detected?

If you're curious about the defensive side:

**Detecting the LD_PRELOAD hook:**
- Audit tools constantly watch `/etc/ld.so.preload` for unauthorized entries.
- Statically compiled binaries (no dynamic libc linking) completely bypass the hook — the hidden files instantly reappear.

**Detecting the kernel module:**
- As long as the module doesn't delete itself from the kernel's module list, `lsmod` will show it.
- On hardened systems with Secure Boot and module signing enforced, the kernel will refuse to load `ceyro_kit.ko` entirely unless it's signed with a trusted key stored in the UEFI.
