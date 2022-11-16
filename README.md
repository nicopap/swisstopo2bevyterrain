# swisstopo to bevyterrain

A tool and unix shell script to download and convert [Swisstopo] geographic data
for use with [`bevy_terrain`].

## Requirements

This relies on a POSIX environment, `libtiff` utilities and a rust toolchain.

## Steps

Please read carefully the [script](./full_script.sh) and **source** it once you
are ready.

Make sure to not run it (`./full_script.sh`) but instead source it
(`. full_script.sh`). It seems `cd` doesn't work in scripts like I expected.

[Swisstopo]: https://www.swisstopo.admin.ch/en/geodata.html
[`bevy_terrain`]: https://github.com/kurtkuehnert/bevy_terrain