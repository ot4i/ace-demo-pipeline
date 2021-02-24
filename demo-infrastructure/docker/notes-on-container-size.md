# App Connect Enterprise container size notes

The ACE software product download is roughly 1.4GB at 11.0.0.9 and unzips to 
more than that; this is larger than some other systems, and not all of it is 
used when running message flows, so shrinking the image looks appealing when
looking at container management (pull times, bandwidth quotas, etc).

However, this concern is sometimes confused with the memory consumption of a
server at runtime, when in fact the two issues are rather different:

 - It is quite possible to have a large disk footprint without actually using
   very much memory: the ACE toolkit is a significant fraction of the overall
   disk space used by the ACE product, and yet is not used at runtime and so
   takes up no memory.
 - Processing large messages inefficiently can consume large amounts of memory
   regardless of the image size: making many copies of messages (or parts thereof)
   can exhaust heap space no matter how small a disk footprint can be achieved.
 - Where the two concerns overlap is the area of runtime components that are
   not used by a specific set of flows, and these tend to be small: the 
   Global Cache is always loaded by default, for example, even if the flows 
   do not use it. Only when scaling a solution up to many containers does this
   become a major concern, as both the on-disk and in-memory footprints will
   start to add up to something noticeable.

This demo uses several different containers for different purposes, depending
on the use case, and it is expected that other organisations will have a similar
approach.

## Scenarios for different container images

For the demo, images built from https://github.com/ot4i/ace-docker/tree/master/experimental 
are used as a base for two stages, and a separate full image is built for the
Jenkins builds (because it has to use jenkins/jenkins:lts as the base image).

 - For Jenkins builds running on a VM, a complete ACE image is used so that 
   all of the commands are available should they be needed. Although mqsipackagebar 
   can be used for most purposes, mqsicreatebar is still required for a few cases 
   and requires a toolkit install to be present in the image. 
   The resulting image is very similar to experimental/ace-full from an ACE
   point of view, but also includes a Jenkins runtime and IBM cloud tools; this 
   results in a large container size (over 3GB) but that is less important due
   to running on a single host (the image is rarely pulled).
 - TravisCI, on the other hand, has to pull the ACE images every time to run 
   build and unit tests, and so needs a much smaller image. Note that TravisCI
   can be customised in various ways to avoid having to pull the images every
   time, but the default public TravisCI instances usually have to pull the
   images, and so we build on experimental/ace-minimal-11.0.0.9-alpine to keep the
   size down to less than 400MB compressed. This still takes about 30 seconds
   to pull, but is much better than attempting to pull multiple gigabytes. 
   Using a cut-down image works because the sample application in this repo can
   use Maven (installed in the image) and mqsipackagebar, as otherwise a toolkit 
   image would be needed and the size would be much greater. TravisCI builds run
   for all PRs, and these happen a lot more often than Jenkins builds, so speed is
   more important and in this particular case image size has a big impact on 
   build speed.
 - Runtime containers also need to be small to fit into the free tier of the IBM
   Cloud Registry, and can in fact be smaller than the TravisCI container due to 
   not needing Maven; these are also based on the experimental/ace-minimal images. 
   They tend to be pulled less than the TravisCI images, but much more than the 
   Jenkins images, and the runtime images change a lot more frequently as well.

Other scenarios are clearly possible, such as a Jenkins system running in a cloud
and using dynamic containers for each build stage, or multiple runtime containers 
with different pre-reqs installed (databse drivers in one, ERP connectors in another, etc).

Using different images for different stages does bring with it a small risk that 
tests will pass in the early stages and then the application will fail at runtime,
but the risks can be managed by testing in the pre-prod stage, where the containers
should match the production images.

## What can be removed?

The experimental/ace-minimal Dockerfiles in the repo mentioned above contain lists
of files that can be removed, with various components in different exclusion files,
and the details are best seen there. However, some general points apply here.

 - The toolkit can be removed without affecting the server runtime
 - ODBC drivers that are not used can be removed, as can XSLT nodes, etc.
 - The WebUI can be excluded, but the server must be told not to use it; several other 
   components follow this pattern.
 - Switching the JDK out and using a JRE saves space without reducing functionality.
 
The results of various options are documented in the experimental repo README.md and
are not repeated here; the ACE development organisation runs tests in a similar way
with some components disabled internally, but see the "Support" section below for 
more information.

Removing components incorrectly is likely to result in the server failing to start
rather than have subtle errors during runtime: the complete absence of a JVM, or a
missing message flow node (such as XSLT), or any other large missing piece would 
cause the server to print errors and then exit.

## Cloud runtime limits

Lower the container image size will reduce the disk usage locally and in a registry, 
and will also keep the bandwidth down when images are pulled (by TravisCI, for example).
This can be important when working with image registries that have bandwidth quotas
as well as disk usage limits; the IBM Cloud Registry has both:
```
[kenya:/] ibmcloud cr quota
Getting quotas and usage for the current month, for account 'TREVOR DOLBY's Account'...

Quota          Limit    Used   
Pull traffic   5.0 GB   334 MB   
Storage        512 MB   327 MB   

OK
```
Not only would attempting to store the ace-full image go over the disk usage quota, it
would also cause the available bandwidth to be used up very quickly. Note that the IBM
Cloud Registry shows compressed images sizes, and bandwidth is counted on the basis of
compressed data flowing in and out, so the numbers are smaller than the equivalent image
seen via "docker images".

For memory consumption, by default the sample app from this repo uses around 150MB 
initially, and runs fine with a 200MB container limit; the JVM will auto-adjust the heap
size for Java code to use, and so the tuning of memory constraints is likely to depend
on the application.

## Support

Running ACE servers in containers is a supported option and does not require the use of 
the ACE Certified Container; the general support statement is in the Knowledge Center
here https://www.ibm.com/support/knowledgecenter/SSTTDS_11.0.0/com.ibm.etools.mft.doc/bz91310_.html

The containers mentioned above are by default built using the Developer Edition of the
product and are therefore intended for use in development and test scenarios. For users 
with entitlement to the ACE product, the images can be built with a copy of the ACE server
code instead of pulling in the Developer Edition install file.

Removing individual components is not officially supported, and for IBM support to be able
to help in case of issues a recreate on a full image would be needed. For this reason the
smaller images may be more appropriate in the earlier pipeline stages, where smaller 
footprint and faster pull times are important.

If more comprehensive support is needed for smaller images, then a "Request for Enhancement"
can be submitted here: https://www.ibm.com/developerworks/rfe/execute?use_case=submitRfe
