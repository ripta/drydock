# drydock

(WORK IN PROGRESS)

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

## Production Installation

Either (a) `gem install dry-dock`, or (b) add "dry-dock" to your project's Gemfile,
and run `bundle`. Sorry, but the gem name `drydock` was already taken by a defunct
gem, and I'm too lazy to contact them; the binary and name of the project, however,
are both `drydock`.

In your project's root directory, you'll want to create a `Drydockfile` containing
drydock functions. When you're ready, build an image using:

```
$ drydock
```

Alternatively, point drydock to a directory containing the `Drydockfile`, or to any
file to treat it as the `Drydockfile`, e.g.:

```
$ drydock ~/source/miniproject # project directory expects a file named Drydockfile
$ drydock ~/source/miniproject/drydock-definition.rb # expects a drydock-definition.rb
```

Example `Drydockfile`s may be seen in `examples/`.

## Development Installation

This is needed if you plan on hacking drydock:

```
$ git clone git@github.com:ripta/drydock.git
$ bundle
```

## Roadmap

1. Customizable caching subsystem.
4. Customizable caching rules.
