# Access Baobab and Yggdrasil

UNIGE is supported by clusters of Baobab and Yggdrasil.

This cli takes a particular approach to dealing them: all is done client-side, and every intervention is by ssh. This approach is suitable when it is not desirable to keep track of multiple locations: only client location matters, all remote locations are mirrors and caches.

```bash
$ git clone https://github.com/volodymyrss/cli-bao-ygg-unige
$ make -C cli-bao-ygg-unige

$ pip install keyring
$ keyring set unige $(whoami) # set your account credentials (stored in your gnome keyring)

$ bao # login
$ bao-list-functions # convenience functions

or:

$ ygg # login
$ ygg-list-functions # convenience functions

```

