# MOSAIC AR bridge revival

This branch revives the 2018 Spring/ARCore experiment without adding a game-simulation dependency on Recoil.

## Architecture

- **MOSAIC LuaUI widget**: LAN discovery/pairing, AR pose receive, camera control.
- **Android ARCore app**: camera passthrough, plane/table anchor, pose transmission, transparent Spring overlay.
- **Recoil**: ordinary renderer. No synced changes and no gameplay protocol changes.
- **Transport**: local Wi-Fi UDP on port 9000. No cloud service is part of the runtime protocol.

The first implementation preserves compatibility with the old 2018 `SPRINGAR;` protocol while adding `MOSAICAR/2`.

## Current milestone

`luaui/widgets_mosaic/camera_mosaic_ar_bridge.lua` is disabled by default. Enable it in the widget selector. It:

1. opens non-blocking UDP/9000 using Recoil's built-in LuaSocket,
2. broadcasts a pairing offer,
3. accepts the new v2 protocol or the old ARDev APK messages,
4. converts anchor-relative ARCore pose into Spring coordinates,
5. drives Recoil's existing **free camera** via `Spring.SetCameraState`,
6. restores the user's previous camera when the AR device disconnects.

This proves the part that previously required the custom `ARController`: current Recoil already exposes enough camera control that the dedicated engine camera is unnecessary.

## Remaining render transport

Do **not** stream full frames through `gl.ReadPixels` in Lua. The API materializes pixels as Lua tables and is unsuitable for a video path.

The old `PicassoCT/spring:arcamdev` branch confirms the original intended architecture: `StreamingController` + OpenH264 streamed an engine FBO to the phone. For modern Recoil the minimal native addition should be a generic, opt-in framebuffer/video stream hook; pairing, transforms and camera selection stay entirely in this widget.

The Android app can then composite decoded RGBA/video over the ARCore camera feed. The engine hook should be generic rather than MOSAIC-specific and inactive unless requested by LuaUI.
