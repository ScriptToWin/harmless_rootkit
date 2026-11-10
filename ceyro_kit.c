#include <linux/module.h>
#include <linux/kernel.h>
#include <linux/init.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Ceyro");
MODULE_DESCRIPTION("LKM Hiding & Banner Demonstration");
MODULE_VERSION("1.0");

// Called when the module is loaded into the kernel
static int __init ceyro_kit_init(void) {
    // Print ASCII banner to the kernel log (dmesg)
    printk(KERN_INFO "\n"
    "####################################################\n"
    "#  ____              _    _ _   _              _   #\n"
    "# |  _ \\ ___   ___  | | _| (_) | |_ ___  __| |  #\n"
    "# | |_) / _ \\ / _ \\ | |/ / | | __/ _ \\/ _` |  #\n"
    "# |  _ < (_) | (_) | |   <| | | ||  __/ (_| |  #\n"
    "# |_| \\_\\___/ \\___/  |_|\\_\\_|_|\\__\\___|\\__,_|  #\n"
    "#                                                  #\n"
    "#         rootkitted by Ceyro                      #\n"
    "#         find the kit! good luck!                 #\n"
    "####################################################\n");

    /*
     * Note on hiding implementation:
     * In a research or simulation environment, this is where you'd register
     * a hook (e.g. via ftrace_set_filter) on functions like 'sys_getdents64'
     * to filter specific file structures from memory.
     */

    return 0;
}

// Called when the module is removed from the kernel
static void __exit ceyro_kit_exit(void) {
    printk(KERN_INFO "Ceyro Kit unloaded successfully.\n");
}

module_init(ceyro_kit_init);
module_exit(ceyro_kit_exit);
