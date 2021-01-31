# Applivery iOS Deploy Step

This is the new and official [Applivery.com](http://www.applivery.com) step to deploy iOS Apps in [Bitrise.io](http://bitrise.io).

## How to use this Step

Can be run directly with the [bitrise CLI](https://github.com/bitrise-io/bitrise),
just `git clone` this repository, `cd` into it's folder in your Terminal/Command Line
and call `bitrise run test`.

*Check the [`bitrise.yml`](bitrise.yml) file for required inputs which have to be
added to your `.bitrise.secrets.yml` file!*

## Step configuration
* **APPLIVERY_APP_TOKEN:** This is the APP Token to identify and access your App. You can follow [this tutorial](https://www.applivery.com/docs/integrations/bitrise/) to configure your Applivery App token.

*Check [`step.yml`](step.yml) file for more information*
