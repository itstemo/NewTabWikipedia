# Wikipedia New Tab Chrome extension

This directory contains the dependency-free Chrome MV3 extension. It replaces
the new-tab page with one random Wikipedia entry at a time.

## Install locally

1. Open `chrome://extensions`.
2. Enable **Developer mode**.
3. Choose **Load unpacked**.
4. Select this directory.

The queue is stored in `localStorage`, so entries can be painted immediately
without waiting for an asynchronous storage API. The network refills the queue
in the background, and the previous entry is used when Wikipedia is unavailable.
