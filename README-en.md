# NHENTAI-CROSS

## [简体中文](README.md) | English

[![license](https://img.shields.io/github/license/niuhuan/nhentai-cross)](https://raw.githubusercontent.com/niuhuan/pikapika/master/LICENSE)
[![releases](https://img.shields.io/github/v/release/niuhuan/nhentai-cross)](https://github.com/niuhuan/pikapika/releases)
[![downloads](https://img.shields.io/github/downloads/niuhuan/nhentai-cross/total)](https://github.com/niuhuan/pikapika/releases)

A beautiful and cross platform *NHentai Client*. Support desktop and mobile phone (Mac/Windows/Linux/Android/IOS).

## Captures

#### Comic list

![](images/comic_list.png)

#### Comic info

![](images/comic_info.png)

#### Comic reader

![](images/comic_reader.png)


## Build

- Project struct
  ![](images/technologies.png)
- mobile
  ```shell
  # see go/mobile/*.sh
  # 1. bind go code to .arr or .xcframework
  gomobile bind -target=$target -o $libraryLocal $project/go/mobile
  # 2. flutter build
  flutter build $system-package
  ```
- desktop
  ```shell
  hover run
  ```
