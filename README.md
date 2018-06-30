# vSphere Integrated Containers Tools

## Overview

vSphere Integrated Containers Tools are a collection of tools used during the
development of vSphere Integrated Containers projects (e.g., [engine][engine],
the [UI plugin][ui], and the [OVA packaging][product]). Maintaining these tools
in this separate repository allows use by each project, without duplication or
artificial dependency relationships; enables use of a separate CI/CD pipeline
for these tools; and makes it easier for other projects to leverage the tools
for their own use cases.

[engine]:https://github.com/vmware/vic
[ui]:https://github.com/vmware/vic-ui
[product]:https://github.com/vmware/vic-product

## Contributing

The vic-tools project team welcomes contributions from the community. If you
wish to contribute code and you have not signed our contributor license
agreement (CLA), our bot will update the issue when you open a Pull Request.
For any questions about the CLA process, please refer to our [FAQ][cla]. For
more detailed information, refer to [CONTRIBUTING.md](CONTRIBUTING.md).

[cla]:https://cla.vmware.com/faq

## License

The vic-tools project is provided under the Apache 2.0 license. For detailed
information, refer to [LICENSE.md](LICENSE.md) and [NOTICE.md](NOTICE.md).
