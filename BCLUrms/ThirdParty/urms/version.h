#ifndef URMS_VERSION_H
#define URMS_VERSION_H

#define URMS_VERSION_MAJOR "3"
#define URMS_VERSION_MINOR "3"

#ifdef _MSC_VER
#pragma message ("Building URMS_VERSION_MAJOR " URMS_VERSION_MAJOR)
#endif


// include the detail rather than defining it here
// so that it can be put on the gitignore file
#include "version_detail.h"


#endif /* URMS_VERSION_H */
