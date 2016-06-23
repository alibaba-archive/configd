# configd
Load your configs, merge into one json file

[![NPM version][npm-image]][npm-url]
[![Build Status][travis-image]][travis-url]

## Usage

`configd source1 source2 protocol://source3 ... destination`

## Readers pattern

| Reader     | Pattern            | Example                                                            |
|:-----------|:-------------------|:-------------------------------------------------------------------|
| http/https | `/^http(s)?:\/\//` | `http://localhost:3333/http.json`                                  |
| ssh        | `/^ssh\:\/\//`     | `ssh://user@host:~/ssh.json`                                       |
| git        | `/^git\:\/\//`     | `git://https://github.com/teambition/configd:test/assets/git.json` |
| local      | `/.*/`             | `./assets/ext.js`                                                  |

## Changelog

### 0.1.0

- Add plugin support

## TODO

* Accomplish mongo router

## LICENSE

MIT

[npm-url]: https://npmjs.org/package/configd
[npm-image]: http://img.shields.io/npm/v/configd.svg

[travis-url]: https://travis-ci.org/teambition/configd
[travis-image]: http://img.shields.io/travis/teambition/configd.svg
