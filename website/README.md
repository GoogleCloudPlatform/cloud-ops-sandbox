# Stackdriver Sandbox Website

The Stackdriver Sandbox website is currently deployed at [stackdriver-sandbox.dev](stackdriver-sandbox.dev).

## Website Architecture

The website is currently set-up using a static html page and deployed in App Engine.

Important files and directories relevent to the website include:
* `app.yaml` - located in the main project directory, this file specifies python run-time and the locations of important files. In order to deploy through App Engine, it is critical for this file to exist and be located in the main project directory.
* `index.html` - located in `website/` directory. This is the main file for the website.
* `main.css` - located in `website/css/` directory. This is the style sheet for Stackdriver Sandbox's website.
* `images/` - located in `website/` directory. Any images on the website should be located in this directory.
* `cloudbuild.yaml` - located in `website/` directory. It is important for this file to be here, since the website is built on App Engine using a build trigger within `stackdriver-sandbox` project on Google Cloud Platform. This build-configuration should be available in order for the website to be automatically deployed.

The website is automatically deployed by App Engine using Cloud Build. Every time code is pushed to `master`, a build trigger is run that builds the website.

## Contributing Guidelines

1. Test locally by making changes and using the following commands within the root directory:
```bash
$ gcloud app deploy app.yaml
$ gcloud app browse
```
**Note:** In order to run these commands, it is important to install gcloud tools. Documentation on that can be found [here](cloud.google.com/source-repositories/docs/quickstart-deploying-from-source-repositories-to-app-engine).
