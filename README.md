A SAMBA Image that is updated automatically using mend renovatebot with the latest stable versions of SAMBA and latest Ubuntu LTS.

## Usage

```shell
docker start \
    -v config:/etc/samba \
    -v pids-and-sockets:/run \
    -v locks:/var/cache/samba \
    -v state:/var/lib/samba \
    -v logs:/var/log/samba
```
## Known issues

### `directory_create_or_exist: mkdir failed on directory /var/lib/samba/private/msg.sock: No such file or directory`

A directory called `private` inside the `state` volume should exists and it is not created by Samba itself.

You must create it manually. It depends on how you have deplyed this image.
