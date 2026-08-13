# Dashboard Telemetry Audit

## Scope and evidence standard

This audit covers only the information needed for the next stage of the standalone racing dashboard. It does **not** add vehicle functions to `RacingDashboardMockup.lua`.

A data source is marked **structurally verified** only when the bundled MonetLoader/SAMemory files explicitly declare the field or when the supplied `sampleosd.lua` uses the method. A source is marked **runtime-pending** when its actual value still needs to be observed on the target Android build. This distinction prevents unproven offsets, invented APIs, and silent fallbacks from entering the dashboard.

## Verified source map

| Dashboard field | Structurally verified source | Evidence | Status for integration |
|---|---|---|---|
| Vehicle presence | `isCharInAnyCar(PLAYER_PED)` | Used as the render condition in `sampleosd.lua`; the bundled `ContextDetectorTest.lua` uses it as an opcode fallback. | Suitable for an initial **automobile-only** test. |
| Vehicle handle | `storeCarCharIsInNoSave(PLAYER_PED)` | Used in `sampleosd.lua` before every vehicle read. | Suitable, with existence and pointer checks. |
| Vehicle pointer | `getCarPointer(car)` | Used in `sampleosd.lua` before `ffi.cast`. | Suitable, provided the returned pointer is non-zero. |
| CVehicle cast | `ffi.cast('struct CVehicle*', carPtr)` after `shared.require 'CVehicle'` | This is the exact mechanism used in `sampleosd.lua`; the SAMemory loader supplies the C structure. | Suitable, wrapped in `pcall`. |
| Speed | `getCarSpeed(car) * 3.6` for km/h | The supplied sample uses this exact conversion. The bundled cheat-menu modules also call `getCarSpeed`. | Suitable for the first live version. |
| Throttle | `vehicleData.fGasPedal` | Declared as `float fGasPedal` in `SAMemory/game/CVehicle.lua`. | Suitable for a continuous throttle bar; runtime range must be observed first. |
| Brake | `vehicleData.fBreakPedal` | Declared as `float fBreakPedal` in `SAMemory/game/CVehicle.lua`. The spelling in the bundled struct is **`Break`**, not `Brake`. | Suitable for a continuous brake bar; runtime range must be observed first. |
| Gear | `vehicleData.nCurrentGear` | Declared as `unsigned char nCurrentGear` in `SAMemory/game/CVehicle.lua`; the supplied sample reads it directly. | Suitable, but its reverse/neutral representation must be confirmed during device testing. |
| Vehicle health | `vehicleData.fHealth` or `getCarHealth(car)` | `fHealth` is declared in `CVehicle`; `getCarHealth` is used throughout bundled scripts. | Optional; safe for a later health display. |
| Automobile engine revs | `CAutomobile.field_804` with comment `m_fEngineRevs` | Explicitly declared in `SAMemory/game/CAutomobile.lua`. | **Runtime-pending.** Use only after a raw-value probe confirms behavior and range on the target build. |
| Motorcycle audio revs | `CBike.field_808` with comment `m_fGasPedalAudioRevs` | Explicitly declared in `SAMemory/game/CBike.lua`. | Not equivalent to verified engine RPM; do not use as the common RPM source. |
| Fuel | No generic fuel quantity found in the audited `CVehicle`, `CAutomobile`, or `CBike` structures. | Search found only `bPetrolTankIsWeakPoint`, a damage-related flag rather than a fuel level. | **Unavailable** without a server-specific source or a separate custom system. |
| Widget brake press | Widget IDs `WIDGET_ACCELERATE`, `WIDGET_BRAKE`, and `WIDGET_HANDBRAKE` exist in `widgets.lua`. | The file contains IDs only; it does not export `widgets.isWidgetPressed`. | Do not rely on `widgets.isWidgetPressed` as a verified API. Use `fGasPedal`/`fBreakPedal` instead. |

## Important exclusions

The following are intentionally excluded from the first integration because they are not proven for this device/build:

| Excluded item | Reason |
|---|---|
| Hard-coded memory offsets such as `carPtr + 0x420` or `carPtr + 0x48B` | No bundled struct evidence established these offsets for this MonetLoader Android build. |
| `vhud_lib.getVehicleData` | The project library did not define this function, so calling it caused the observed `nil value` crash. |
| A universal “native RPM” field for every vehicle type | `CAutomobile` and `CBike` expose different, differently named fields. A single universal value is not established. |
| Fuel display driven by GTA memory | No generic fuel-level field was found in the audited native structures. |
| `widgets.isWidgetPressed` | The local widget library exports IDs only, not a verified press-state function. |

## Recommended first live-data scope

The first live dashboard should support **automobiles only**. This is deliberate: the existing sample uses `isCharInAnyCar`, and the `CAutomobile` definition contains the explicitly named `m_fEngineRevs` field. The first probe should collect raw values—not alter the dashboard—for the following fields:

1. `getCarSpeed(car) * 3.6`.
2. `CVehicle.fGasPedal`.
3. `CVehicle.fBreakPedal`.
4. `CVehicle.nCurrentGear`.
5. `CAutomobile.field_804` (`m_fEngineRevs`).
6. `CVehicle.fHealth`.

The probe should display raw values while the vehicle is stationary, accelerating, braking, reversing, and changing gear. Only after the recorded behavior is sensible should those fields be connected to the dashboard. RPM will remain a static visual value until that probe validates `CAutomobile.field_804` on the user’s device.

## Local evidence

| Ref. | Local source | Relevant evidence |
|---|---|---|
| S1 | `sampleosd.lua.txt`, lines 1–57 | Imports `ffi`, `widgets`, and `SAMemory.shared`; loads `CVehicle`; gets the vehicle pointer; casts `CVehicle`; reads `fGasPedal` and `nCurrentGear`; computes speed from `getCarSpeed`. |
| S2 | `MonetLoader-lib-full/lib/SAMemory/game/CVehicle.lua`, lines 233–255 | Declares `fGasPedal`, `fBreakPedal`, `nCurrentGear`, `fWheelSpinForAudio`, and `fHealth`. |
| S3 | `MonetLoader-lib-full/lib/SAMemory/game/CAutomobile.lua`, lines 53–67 | Declares `field_804` with the comment `m_fEngineRevs`. |
| S4 | `MonetLoader-lib-full/lib/SAMemory/game/CBike.lua`, lines 93–103 | Declares `field_808` with the comment `m_fGasPedalAudioRevs`. |
| S5 | `MonetLoader-lib-full/lib/widgets.lua`, lines 5–14 and 199–204 | Declares widget IDs and exports them globally; it does not define press-state functions. |
| S6 | `testing/ContextDetectorTest.lua`, lines 12–92 | Demonstrates `pcall`-based SAMemory fallback and an opcode fallback for vehicle/context detection. |

## Approval checkpoint

No vehicle function will be added to `RacingDashboardMockup.lua` until the user approves the proposed **automobile-only telemetry probe** and provides its on-device output or screenshot.
