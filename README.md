# x

A lightweight server framework written in C use Lua as script language.

[![license](https://img.shields.io/badge/license-MIT-brightgreen.svg?style=flat)]

--------

## Depend

- sudo apt-get install libreadline-dev(debain)
- yum install readline-devel(centos)

## Build

- make linux  (linux)
- make macosx (mac)

## Install
- make install

## Run
    x <configfile>

## Config
- daemon, 1 --> run as daemon, 0 --> normal
- bootstrap, lua entry file
- lualib_path, will append the package.path (in luaVM)
- lualib_cpath, will append the package.cpath (int luaVM)
- logpath, when run as daemon, all print message will write to [logpath]/silly-[pid].log file
- pidfile, when run as daemon, 'pidfile' will used by run only once on a system

## Demo
- process/csdemo

## ConfigMgr
- run ./x process/configmgr/entry.config to generate sample config file for each process

## Test
- all the test code will be included into ./test folder
- run x test/test.conf will auto test all module

## Misc
- deps/lua is no a pure lua, and can be replaced by pure lua
- extra features are lfs and lcalender
