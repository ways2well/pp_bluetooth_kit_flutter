# Ways2Well fork

Fork of [LefuHengqi/pp_bluetooth_kit_flutter](https://github.com/LefuHengqi/pp_bluetooth_kit_flutter),
branched from upstream tag **0.0.45** (`4669428`).

It exists for one reason: **the LEFU CF597 8-electrode scale cannot be read on
Android with the SDK version upstream pins.**

## The bug

Upstream pins `com.lefu:*:4.2.1.1`. That release's Android BLE transport is a
vendored copy of Xiaomi's `com.lefu.bluetooth.library` ("miio"), and it enables
notifications on characteristic `fff1`:

```
setCharacteristicNotification(fff1, enable=true)
getDescriptor for notify null!            <-- no 0x2902 CCCD on fff1
BleNotifyRequest >>> request complete: code = -1
readCharacteristic failed                 <-- fff1 has no READ property either
```

On the CF597 the notify characteristic is **`fff4`**, not `fff1`. The
subscription never happens, the scale drops the link a couple of seconds later,
and the app sees `connectionLost` with no weight ever delivered. It reproduces
100% of the time, on a fresh unbonded connection, with a cleared GATT cache.

iOS is unaffected — it uses the vendored `PPBluetoothKit.xcframework`, a
different transport that subscribes correctly.

**4.2.1.1** bundles that transport inline in its own AAR. **4.6.20** externalises
it as a transitive dependency, `com.lefu:bluetoothkit:1.5.5`, and that build
subscribes to `fff4`:

```
setCharacteristicNotification(fff4, enable=true)
onDescriptorWrite ... character = 0x0000fff4, descriptor = 0x00002902, status = 0
BleNotifyRequest >>> request complete: code = 0
```

Verified end to end on a Pixel 4 (Android 13): `scanning → connecting → waiting →
measuring → analyzing → success`, `PP_ERROR_TYPE_NONE`.

## Changes vs upstream 0.0.45

1. **`android/build.gradle`** — `ppbasekit` / `ppbluetoothkit` `4.2.1.1` → `4.6.20`.
   All 43 `com.lefu.*` / `com.peng.*` classes this plugin binds against still
   exist in 4.6.20. This also pulls in `com.lefu:bluetoothkit:1.5.5` transitively
   (4.2.1.1 had no such dependency — it inlined the transport). Neither AAR ships
   native libraries, so the 16 KB page-size constraint that motivated upstream's
   `4669428` does not apply; `ppcalculatekit` stays commented out.

2. **`android/src/main/kotlin/.../PPLefuBleConnectManager.kt`** — one call site.
   After 4.2.1.1, `PPBlutoothPeripheralJambulController.startBroadCast` changed
   from `(PPUnitType, Int, String)` to `(PPUnitType, PPUserModel?,
   PPDeviceModel?)`. The surrounding code already built the `PPUserModel` and
   threw it away, so it now feeds the new parameter. This is the Jambul
   broadcast path; the CF597 is a Torre device and never reaches it.

Nothing else is touched — no Dart, no iOS, no behavioural changes.

## Upstream status

Upstream's newest tag (0.1.1 at the time of writing) still passes the old
signature, so it is still built against 4.2.x. This should be reported to LEFU;
if they publish a plugin release built against 4.6.x, this fork can be retired.

## Rebasing

```bash
git remote add upstream https://github.com/LefuHengqi/pp_bluetooth_kit_flutter.git
git fetch upstream
git rebase upstream/master   # expect conflicts only in the two files above
```
