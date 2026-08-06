#!/bin/bash
sed -i '/dependency_overrides:/,$d' pubspec.yaml

cat << 'INNER_EOF' >> pubspec.yaml
dependency_overrides:
  cubepod:
    path: ../../packages/cubepod
  cubepod_core:
    path: ../../packages/cubepod_core
  cubepod_state:
    path: ../../packages/cubepod_state
  cubepod_flutter:
    path: ../../packages/cubepod_flutter
  cubepod_network:
    path: ../../packages/cubepod_network
  cubepod_async:
    path: ../../packages/cubepod_async
  cubepod_query:
    path: ../../packages/cubepod_query
  cubepod_router:
    path: ../../packages/cubepod_router
  cubepod_storage:
    path: ../../packages/cubepod_storage
  cubepod_sync:
    path: ../../packages/cubepod_sync
  cubepod_events:
    path: ../../packages/cubepod_events
  cubepod_resources:
    path: ../../packages/cubepod_resources
  cubepod_scheduler:
    path: ../../packages/cubepod_scheduler
  cubepod_enterprise:
    path: ../../packages/cubepod_enterprise
  cubepod_annotation:
    path: ../../packages/cubepod_annotation
  cubepod_generator:
    path: ../../packages/cubepod_generator
  cubepod_testing:
    path: ../../packages/cubepod_testing
INNER_EOF
