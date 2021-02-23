# config rime in linux

arch

install

- fcitx-rime
- rime-wubi

switch to rime method

config `~/.config/fcitx/rime/default.custom.yaml`

```
patch:
  schema_list:
    - schema: wubi86
```

然后右键，点击重新部署，即可生效

https://wiki.archlinux.org/index.php/Rime
