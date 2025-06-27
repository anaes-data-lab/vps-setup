#!/bin/bash
chmod a+rx /opt
chmod a+rx /opt/tljh
find /opt/tljh/user -type d -exec chmod a+rx {} +
chmod -R a+r /opt/tljh/user
