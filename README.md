# File System Events

This project shows how to track file system
activity using event driven state machines.

## Examples

### Scanning directory

```
file system events = 0x40000020
DirMon-1 @ WORK got 'F5' from OS
'/tmp/test/': opened
file system events = 0x40000001
DirMon-1 @ WORK got 'F0' from OS
'/tmp/test/': accessed
file system events = 0x40000001
DirMon-1 @ WORK got 'F0' from OS
'/tmp/test/': accessed
file system events = 0x40000010
DirMon-1 @ WORK got 'F4' from OS
'/tmp/test/': closed (read)
```

### Touching a file

```
file system events = 0x00000020
DirMon-1 @ WORK got 'F5' from OS
'a': opened
file system events = 0x00000004
DirMon-1 @ WORK got 'F2' from OS
'a': metadata changed
file system events = 0x00000008
DirMon-1 @ WORK got 'F3' from OS
'a': closed (write)
```
