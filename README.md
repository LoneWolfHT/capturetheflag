# Capture The Flag

[![Build status](https://github.com/MT-CTF/capturetheflag/workflows/build/badge.svg)](https://github.com/MT-CTF/capturetheflag/actions)

* Fast rounds of CTF games.
* Removed nodes for focus.

## Installation

Capture the flag uses several submodules. Make sure to grab them all by cloning like this:

```sh
git clone --recursive https://github.com/MT-CTF/capturetheflag.git
```

## Development

* Lone_Wolf uses Visual Studio Code with these extensions:
  * https://marketplace.visualstudio.com/items?itemName=sumneko.lua
  * https://marketplace.visualstudio.com/items?itemName=dwenegar.vscode-luacheck

## System Requirements

### Recommended

* Hosting your server using the `dummy` backend.

* Hosting using the `redis` rankings backend:
  * Ubuntu:
    * `sudo apt install luarocks redis`
    * `sudo luarocks install luaredis`
    * Add `ctf_rankings` to your secure.trusted_mods. MIGHT BE POSSIBLE FOR OTHER MODS TO BREACH SECURITY. MAKE SURE YOU ADD NO MALICIOUS MODS TO YOUR CTF SERVER
    * Run something like this when starting your server (With parentheses): (cd minetest/worlds/yourworld && redis-server) | <command to launch your minetest server>

## License

Created by [rubenwardy](https://rubenwardy.com/) and [Lone_Wolf](https://github.com/LoneWolfHT).

Licenses where not specified:
Code: zlib license
Textures: CC-BY-SA 3.0

### Textures

* [Header](menu/header.png): CC BY-SA 4.0 by xenonca

### Mods

Check out [mods/](mods/) to see all the installed mods and their respective licenses.
