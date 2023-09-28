# :gear: GEAR :gear:

[![gh-ci][gh-ci-img]][gh-ci]

- Installs pretty much **anything** on Linux (w/o you having to care much, how)
- And **a lot** on OSX.
- Or when you don't have or want to use(!) root.

Mainly intended to be used on servers, which you don't own / where others are also
active, compared to solely using the system package manager.



## Basic Operation

### When you have `git` already

1. Clone the repo
2. Run `gear` script (see below)

### Without `git`

E.g. for cloud init:</summary>

```bash
# get it, e.g. in a cloud-init script:
wget "https://raw.githubusercontent.com/AXGKl/gear/master/gear" 
chmod +x gear
./gear <e[nsure] | i[nstall]> <stuff> 
```
</details>


- "Ensure": Install only when command is not found 
- "Install": Always try install using the supported gear managers


## What Happens At First Usage

1. `gear` will put itself into `$HOME/.local/bin`

2. Use various package managers ("gear managers") to install the `<stuff>` you want. That
   will cause the manager specific side-effects then, depending on which one is being utilized - but nothing specific to `gear`, except index lists (see below).

3. When the stuff you list requires to bootstrap gear managers (see below), they require activation in your `.bashrc` or `.zshrc`. This is put into `$HOME/.gears`, and a line to source that at the beginning or your `.bashrc` or `.zshrc` - so, please restart your (bash or zsh) shell then (or source `$HOME/.gears`)
  
4. Index lists are created at gear manager install time, within `$HOME/.config/gear/`, to allow normalized searching for stuff, over various tool managers
 


## Example

This is how you express the `<stuff>` you want:

```bash
# OSX:
$ gear i b:gdu,rg=12.0.0 lazygit mm:firefox,redis-server [asdf][asdf]:nodejs:npm
# Linux with (sudo) root, in addition:
$ gear i n:ruby [brew][brew]:gdu:gdu-go sys:procps
```

This will, on a 'naked' amd64 OSX or Linux system, install 

- [binenv][binenv] (since `b:gdu` specified to install gdu using [binenv][binenv])
- gdu (latest), ripgrep (in given version) using [binenv][binenv] (`b:...`)
- lazygit using [binenv][binenv], since no tool manager was given and [binenv][binenv] is tried first and
  present
- [micromamba][micromamba] (`mm:`) and with it firefox and redis  
- [asdf][asdf] and with it nodejs (testing presence using command `npm`)

without ever requiring a root password, i.e. into your `$HOME`.

On Linux, requiring (sudo) root once at install time in addition:

- [nix][nix] and with it ruby
- linuxbrew and with it gdu (testing presence, using the cmd `gdu-go`)


See for more examples in the [tests](./tests) directory.


## Supported Gear Managers

### Comparison Matrix

|                          | **[binenv][binenv]** | **[asdf][asdf]** | **[micromamba][micromamba]** | **[nix][nix]** | **[brew][brew]** | **sys**[^apt] |
| -                        | -                  | -              | -                          | -            | -              | -             |
| Req. root to once setup  |                    |                |                            | y            | y              | y             |
| Req. root to install pkg |                    |                |                            |              |                | y             |
| Speed                    | +++                | ++             | +                          | +            |                |               |
| System impact            | +++                | ++             | +                          | r            |                |               |
| Parallel versions        | y                  | y              | y[^2]                      | y            |                |               |
| Variety of packages      | -                  |                | +                          | ++           | ++             | ++            |
| Auto inst. dependencies  | -                  | -              | y                          | y            | y              | y             |
| Libraries                | -                  | -              | y                          | y            | y              | y             |
| System impact[^1]        | ++                 | ++             | ++                         | +[^3]        | +[^4]          | -             |
| Multi user access        |                    |                |                            | +            | +[^5]          | +             |
| `man` support            |                    |                | +                          | +            |                | +             |


[^apt]: apt or yum
[^1]: outside user home dir
[^2]: via conda environments
[^3]: `/nix` folder and profile scripts in `/etc`
[^4]: `/home/linuxbrew` directory
[^5]: Via common group


### [binenv][binenv] (alias b)

🟩 Superfast to get to basic tools, which are released as static binaries.  
🟥 Not so many tools  
🟥 When upstream change their release versioning urls, [binenv][binenv] might fail to
download, requires some time to update it's "[distributions][bdistries]" spec. You can
keep a custom one though.

### [asdf][asdf] (a)

🟩 Can install advanced tools via a large set of specific repos with recipees  
🟥 You are dependent on these repo authors, quality wise. 



### [micromamba][micromamba] (mm)

🟩 Technically imho. the most advanced and powerful solution: Puts placeholders into the
compiled artifacts, which are replaced with the install locations only at install time, so
that they can be installed without the need to compile for the prefix. Like (home)brew on
steroids, allowing for versions (via different prefixes - environments) and never
requiring root.  
🟩 Perfect support for scientific tools and or AI related stuff, like pytorch or
tensorflow 

### [nix][nix] (n)
🟩 Also technically impressive - providing everything to build everything from scratch -
in various versions on one system. The binary linking problem they solve via specific
locations they link to using symlinks. 
🟥 Big learning effort for outsiders

### [brew][brew]
An attempt to provide homebrew for linux users. 


### apt or yum (sys, s)

🟩 You profit from giants regarding well tuned package dependency chains, incl. security
backports for older versions outside of upstream  
🟥 Modify the system - as root.    
🟥 Not always the latest and greatest versions
Various attempts to fix this a are complex, e.g. [immutable](https://fedoraproject.org/silverblue/) distries.

---

> I typically start on a new server with [binenv][binenv] for the basic terminal tools and [micromamba][micromamba]
for more complex tools. Then on demand extend to [asdf][asdf] or, when having root, [nix][nix] (explaining to others on
that machine, why there is now a `/nix` directory...).

dnf/apt/yum I try to only use for kernel related stuff.




[binenv]: https://github.com/devops-works/binenv
[bdistries]: https://github.com/devops-works/binenv/blob/develop/distributions/distributions.yaml 
[asdf]: https://asdf-vm.com/
[micromamba]: https://mamba.readthedocs.io/en/latest/user_guide/micromamba.html
[nix]: https://nixos.org/manual/nixpkgs/stable/
[brew]: https://docs.brew.sh/Homebrew-on-Linux
[gh-ci]: https://github.com/AXGKl/gear/actions/workflows/ci.yml
[gh-ci-img]: https://github.com/AXGKl/gear/actions/workflows/ci.yml/badge.svg



