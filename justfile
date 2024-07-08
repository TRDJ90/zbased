default:
    just --list

prepare:
    zigup 0.13.0

build:
    zig build

run:
    zig build run

clean:
    rm -r ./.zig-cache ./zig-out ./zig-cache
