   #!/bin/sh

# Create a new Info.plist prefix header file.
echo "#define URL_SCHEME ${URL_SCHEME:-"ownerchip"}" > "${INFOPLIST_PREFIX_HEADER:-"InfoPlistPrefix.h"}"