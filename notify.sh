#!/bin/bash

tail -F /home/feho/.openmohaa/main/qconsole.log | rg -i 'aimbot|says|KMNERF' --line-buffered | rg -v 127.0.0.1 --line-buffered | xargs -r -d '\n' -I{} curl -fsS --data-binary "{}" https://ntfy.sh/my-mohaa-monitoring-example
