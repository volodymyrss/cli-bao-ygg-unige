# Access Baobab


```bash
$ git clone https://github.com/volodymyrss/access-unige-baobab
$ make -C access-unige-baobab

$ pip install keyring
$ keyring set unige $(whoami) # set your account credentials (stored in your gnome keyring)

$ bao # login
$ bao-list-functions # convenience functions
```
