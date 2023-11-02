# Codespaces

Codespaces are a [feature of GitHub](https://github.com/features/codespaces) that enables
container-based development with VisualStudio Code in a web browser. The container in
which vscode runs is configurable, and this repo uses a container with ACE installed.

Individual developers get sixty hours of container runtime for free (at the time of
writing), and a codespace can be launched from the "Code" menu:

![Codespaces launch](/.devcontainer/codespaces-launch.png)

## Building and testing

The container will start up once the image has been downloaded (usually 20-40 seconds)
and vscode will start automatically. All of the usual ACE commands are present, servers
can be started as usual, etc. For this repo, Maven can be used to build and test the
application and library in the terminal window:
```
mvn --no-transfer-progress -Dinstall.work.directory=/tmp/maven-output/ace-server verify
```
The first Maven run will download lots of plugins, and subsequent runs will be faster.

## Use cases

The default container does not have the ACE toolkit available (the web console is taken
up with vscode and there is no X-Windows display) and so these codespaces are most useful 
for incremental coding and fixing issues. 

For ESQL or Java coding, unit testing, or fixing CI build breaks, codespaces provide an
easy-to-start environment that removes the need to install the product locally while still
allowing building and testing with the actual product.

##  Codespace devcontainer

Codespaces for this repo use the [ace-minimal devcontainer](https://github.com/ot4i/ace-docker/tree/main/experimental/devcontainers)
which is built on the standard Ubuntu devcontainer with ACE and Maven installed. The container
is pre-built for faster startup, but could also be run as a docker build during codespace startup.

## Toolkit-enabled container

This repo has a "toolkit-xvnc" option for codespaces which will use an ACE devcontainer that
can run the toolkit in a browser session; see https://github.com/trevor-dolby-at-ibm-com/ace-vnc-devcontainer 
for details on how to access the toolkit. This option takes significantly longer to start than
the default devcontainer.

