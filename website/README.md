# Cloud Operations Sandbox Website

The Cloud Operations Sandbox website is currently deployed at [cloud-ops-sandbox.dev](https://cloud-ops-sandbox.dev).

## Website Architecture

The website is currently set-up using the [Hugo](https://github.com/gohugoio/hugo) static site generator with the [Docsy](https://github.com/google/docsy) theme and deployed in App Engine.

Important files and directories relevent to the website include:
* `config.toml` - Located in `website/`, this file specifies the hugo properties for the website. This is critical for hugo to build the website
* `content/` - Located in `website/` directory. Contains the main documentation files used to build the website
* `layouts/` - Located in `website/` directory.  Contains static html files used in the site
* `static/` - Located in `website/` directory.  Contains additional files use on the site
* `themes/` - Located in `website/` directory. Contains the submodule Docsy which is used to theme the site

The website is automatically deployed to App Engine. Every time a new version is released, a build trigger is run that builds the website.

## Contributing Guidelines

1. Test locally by making changes and using the following commands within the root directory:
```hugo server
```

The website should be automatically deployed when `push-tags.yml` is run (one of the project's GitHub Actions).

**Note:** In order to run these commands, it is important to install gcloud tools. Documentation on that can be found [here](https://cloud.google.com/source-repositories/docs/quickstart-deploying-from-source-repositories-to-app-engine).