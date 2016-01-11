# drydock

**WARNING:** Work in progress. Although this software has test coverage, it is
considered unstable. Refer to [LICENSE](LICENSE.md) for licensing information.

See section on [Compatibility](#compatibility) for a list of supported Docker
versions for every Drydock version.

[![Automated Build Status](https://travis-ci.org/ripta/drydock.svg)](https://travis-ci.org/ripta/drydock)
[![Code Climate](https://codeclimate.com/github/ripta/drydock/badges/gpa.svg)](https://codeclimate.com/github/ripta/drydock)

A ruby DSL to build your own docker images. Images are built based on instructions
contained in your project's `Drydockfile`.


## Why not Dockerfile?

[Dockerfiles](https://docs.docker.com/reference/builder/) are great to start out
with, but:

1. **They are static,** which isn't necessarily a bad thing. I'm not opposed to
a declarative approach to building images, but _sometimes_ it may be limiting.
2. **They are less hackable,** because `docker build` doesn't support plugins
to expand its capabilities.
3. **More complicated build pipelines are hard to implement,** or perhaps even
impossible. For instance, being able to build multiple images, then combine them
at the end, would be a nice option. Imagine building your ruby gem dependencies
and node.js dependencies separately, before combining both images into your
application's final image.
4. **Caching rules are fairly limiting.** For instance, when your Gemfile changes,
it would be nice to import a configurably-older image, import the new Gemfile,
and re-run the build. On the other hand, it would be important to be able to limit
the age of the cache.


## Why Drydock?

Drydock interfaces directly with the [Docker Remote API](https://docs.docker.com/reference/api/docker_remote_api/)
via [the docker-api gem](https://github.com/swipely/docker-api/). It's
not for every use case, but it provides great control over what and how an image
is built.

Drydock supports plugins, either provided through ruby gems or ruby files included
in your project being built by Drydock.

Drydockfiles are written in ruby.


## Installation

Either (a) `gem install dry-dock`, or (b) add "dry-dock" to your project's Gemfile,
and run `bundle`.

Sorry, but the gem name `drydock` was already taken by a defunct gem, and I'm too
lazy to contact them; the binary and name of the project, however, are both `drydock`.

In your project's root directory, you'll want to create a `Drydockfile` containing
drydock functions. When you're ready, from your project's directory, build an image using:

```
$ bundle exec drydock
```

or `drydock` directly if you're not using bundler.

Alternatively, point drydock to a directory containing the `Drydockfile`, or to any
file to treat it as the `Drydockfile`, e.g.:

```
$ drydock ~/source/miniproject # project directory expects a file named Drydockfile
$ drydock ~/source/miniproject/drydock-definition.rb # expects a drydock-definition.rb
```

**Example `Drydockfile`s may be seen in the `examples/` directory of the source repo.**


## Drydockfile Syntax

As previously mentioned, Drydockfiles are ruby. The contents of Drydockfile are
evaluated in the context of an instance of {Drydock::Project}; you can refer to
the documentation for it for more in-depth information on each instruction.

Because Drydockfiles are ruby, most constructs should work as-is: you can declare
constants and refer to them later; call `Kernel#abort` to exit the program and
stop the build; and write plugins to be called from within the Drydockfile.

It would help if you understand ruby and
[Dockerfiles](https://docs.docker.com/reference/builder/) before jumping in.

All instructions are evaluated in the order that they are seen; syntax errors or
any logical errors might not be caught until execution arrives at that point.

For a complete and updated list of Drydockfile instructions, see the public API
methods of the {Drydock::Project} class or head to the
[automatically-generated ruby docs](http://www.rubydoc.info/gems/dry-dock).


## Contributing

If you plan on hacking or contributing to drydock, fork the project, create a new
branch, make your changes, commit, and open a pull request.

After cloning your repo, `bundle` should take care of it.


## Release

```
$ bundle
$ # increment VERSION file
$ bundle exec rake gemspec build
$ # upload .gem file to rubygems.org
```


## Roadmap

1. Customizable caching subsystem with pluggable caching strategies.
2. Squashing layers together, with cache support.
3. Unarchiving a file directly into a container.
4. Proper `ONBUILD` implementation and expanded support for hooks.
5. Drydock instructions corresponding to `LABEL`, `VOLUME`, `USER`, and `WORKDIR` Docker instructions.


## Compatibility

The following version combinations are officially tested and supported:

| Docker Versions | Drydock Versions |
| --------------- | ---------------- |
| v1.8.0          | v0.1.0 onwards   |
| v1.9.0          | v0.2.0 onwards   |

Docker v1.7 or earlier is not officially supported, but most functionality should
work, with the exception of:

* The `copy` command, which may fail when unpacking into the root `/` of the container.
* The `import` command, which requires the `/containers/(id)/archive`. Earlier
  versions of the Docker Remote API implemented `/containers/(id)/copy`; if you'd
  like to add graceful fallback using the aforementioned, contributions are welcome.
