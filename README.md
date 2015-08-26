# drydock

A ruby DSL to build your own docker images. Images are built based on instructions
contained in your project's `Drydockfile`.

## Why not Dockerfile?

Dockerfiles are great to start out with, but:

1. **They are static,** which isn't necessarily a bad thing. I'm not opposed to
a declarative approach to building images, but _sometimes_ it may be limiting.
2. **They are less hackable,** because `docker build` doesn't support plugins
to expand its capabilities.
3. **More complicated build pipelines are hard to implement,** or perhaps even
impossible. For instance, being able to build multiple images, then combine them
at the end, would be a nice option. Imagine building your rubygem dependencies
and node.js dependencies separately, before combining both images into your
application's final image.
4. **Caching rules are fairly limiting.** For instance, if your Gemfile changes,
it would be nice to import a configurably-older image, import the new Gemfile,
and re-run the build.

## Production Installation

Either (a) `gem install drydock`, or (b) add "drydock" to your project's Gemfile,
and run `bundle`.

In your project's root directory, you'll want to create a `Drydockfile` containing
drydock functions. When you're ready, build an image using:

```
$ drydock
```

Alternatively, point drydock to a directory containing the `Drydockfile`, or to any
file to treat it as the `Drydockfile`, e.g.:

```
$ drydock ~/source/miniproject
$ drydock ~/source/miniproject/drydock-definition.rb
```

## Development Installation

This is needed if you plan on hacking drydock:

```
$ git clone git@github.com:ripta/drydock.git
$ bundle
```
