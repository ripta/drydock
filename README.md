# drydock

A ruby DSL to build your own docker images.

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
