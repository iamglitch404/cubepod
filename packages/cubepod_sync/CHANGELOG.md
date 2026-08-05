## 0.1.4

Made conflict resolution strategy configurable per entity type — previously the global strategy was applied to all synced models. Fixed an issue where the offline queue would stall permanently if a record was deleted on the server between the time it was queued and the time the client came back online.

## 0.1.2

Added offline queue persistence so changes survive app restarts. Added conflict detection on sync.

## 0.1.0

Initial release with offline sync support.
