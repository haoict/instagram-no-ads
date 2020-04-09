# Instagram No Ads

Tweak to remove ads on Instagram app for iOS!

Just install, no preferences. Require device jailbroken

## Cydia Repo

[https://haoict.github.io/cydia](https://haoict.github.io/cydia)

## Building

[Theos](https://github.com/theos/theos) required.

```bash
make do
```

## [Note] Advanced thingy for development

### Add SSH key for target deploy device
```
cat ~/.ssh/id_rsa.pub | ssh -p 22 root@192.168.1.21 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

## License

Licensed under the MIT License, Copyright © 2020-present Hao Nguyen <hao.ict56@gmail.com>
