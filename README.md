# heroku-bundles

Import/export your Heroku app.

## Bundle Format

A bundle is a tarball that contains everything your app needs to run.

Your app's current config will be exported into a `.env` file in the bundle.

## Installation

    $ heroku plugins:install https://github.com/ddollar/heroku-bundles

## Usage

    $ heroku apps:clone -a example example-new
    Creating example-new... done
    Creating bundle for example... done
    Downloading: 100.0%
    Uploading bundle... done, v4
    Cloned example to example-new

    $ heroku apps:export -a example
    Exporting example...
    Downloading: 100.0% (ETA: 0s)
    Exported to example.tgz

    $ heroku apps:import example.tgz -a example-new
    Importing example.tgz...
    Uploading: 100.0%
    Replace HEROKU_POSTGRESQL_WHITE_URL with heroku-postgresql? [y/N] y
    Available heroku-postgresql plans:
      dev basic crane kappa ronin fugu ika zilla baku mecha
    Choose a plan [dev]: crane
    Adding heroku-postgresql:crane to example-new... done, $50/mo
    Replace OPENREDIS_URL with openredis: [y/N] n
    Imported to example-new
