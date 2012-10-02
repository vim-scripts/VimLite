#include <linux/init.h>
#include <linux/module.h>

MODULE_LICENSE("GPL");

static __init int hello_init(void)
{
	printk(KERN_ALERT "Hello World!\n");
	return 0;
}

static __exit void hello_exit(void)
{
	printk(KERN_ALERT "Goodbye Hello!\n");
}

module_init(hello_init);
module_exit(hello_exit);