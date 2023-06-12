A SAMBA Image that is updated automatically using mend renovatebot with the latest stable versions of SAMBA and Alpine Linux.

## Usage

```shell
docker start \
    -v config:/etc/samba \
    -v pids-and-sockets:/run \
    -v locks:/var/cache/samba \
    -v state:/var/lib/samba \
    -v logs:/var/log/samba
```
