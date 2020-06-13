# Instagram No Ads

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg?style=flat-square)](http://makeapullrequest.com)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

Free & Open Source Tweak for Instagram app on iOS!

<img src="https://haoict.github.io/cydia/images/instanoads.jpg" alt="Instagram No Ads" width="414"/>

## Features
- Remove Ads (New Feeds and Stories)
- Can save media (Photos, Videos, IGTV, Stories, press and hold to show download option)
- Support iOS 10 (not tested) - 11 (tested) - 12 (tested) - 13 (tested)
- Support latest Instagram version (If it doesn't work, you should update the app to latest version >= 140.0)

## Cydia Repo

[https://haoict.github.io/cydia](https://haoict.github.io/cydia)

## Screenshot

<img src="https://haoict.github.io/cydia/images/instanoadspref.png" alt="Instagram No Ads Preferences" width="280"/>

## Building

[Theos](https://github.com/theos/theos) required.

```bash
make do
```

## Contributors

[haoict](https://github.com/haoict)

[jacobcxdev](https://github.com/jacobcxdev)

Contributions of any kind welcome!

## License

Licensed under the [GPLv3 License](./LICENSE), Copyright © 2020-present Hao Nguyen <hao.ict56@gmail.com>

## [Note] Advanced thingy for development
<details>
  <summary>Click to expand!</summary>
  
  Add your device IP in `~/.bash_profile` or in project's `Makefile` for faster deployment
  ```base
  THEOS_DEVICE_IP = 192.168.1.21
  ```

  Add SSH key for target deploy device so you don't have to enter ssh root password every time
  ```bash
  cat ~/.ssh/id_rsa.pub | ssh -p 22 root@192.168.1.21 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
  ```

  Build the final package
  ```bash
  FINALPACKAGE=1 make package
  ```

</details>
