

## Overview

Docker for building libraries of editors on Android.

## Recommended System Requirements

* **RAM**: 6 GB or more
* **CPU**: dual-core 2 GHz or higher
* **Swap**: at least 2 GB
* **HDD**: at least 160 GB of free space (allocate disk image size for docker in advance)
* **Docker**: version 1.9.0 or later

## Build libraries

    ./docker_build.sh

Use this command to build release libraries.

    ./docker_build.sh debug

Use this command to build developer libraries.

After a successful build, will be created a `libs.zip` file.

## User Feedback and Support

If you have any problems with or questions about this image, please visit our official forum to find answers to your questions: [dev.onlyoffice.org][1] or you can ask and answer ONLYOFFICE development questions on [Stack Overflow][2].

  [1]: https://dev.onlyoffice.org
  [2]: https://stackoverflow.com/questions/tagged/onlyoffice