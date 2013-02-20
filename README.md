# heroku-bundles

Import/export your Heroku app.

## Bundle Format

A bundle is a tarball that contains everything your app needs to run.

Your app's current config will be exported into a `.env` file in the bundle.

## Installation

    $ heroku plugins:install https://github.com/ddollar/heroku-bundles

## Usage

    $ heroku apps:export -a example
    Exporting example...
    Downloading: 100.0% (ETA: 0s)
    Exported to example.tgz
