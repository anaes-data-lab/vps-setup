#!/bin/bash

# Ensure TLJH base directories are accessible
chmod a+rx /opt /opt/tljh

# Set readable and traversable permissions on all files and folders in TLJH user env
find /opt/tljh/user -type d -exec chmod a+rx {} +
find /opt/tljh/user -type f -exec chmod a+r {} +