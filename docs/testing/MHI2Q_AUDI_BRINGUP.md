# Audi MHI2Q AltScreen bring-up (pointer)

The Audi MHI2Q port of the GEN2 AltScreen hook is driven from the sibling
route-guidance project, `mib2q-carplay-rgi`, because on Audi the CarPlay cluster
video is **decoded on the head unit and drawn into a cluster plane** that the
stock encoder re-encodes to the Virtual Cockpit — not injected into MOST as on
Škoda MU1440. See that project's guide for the full build/install/bring-up:

- **`mib2q-carplay-rgi/docs/deploy/altscreen-mhi2q.md`** — architecture, build,
  green-menu M.I.B. install, log checks, and every on-car verify point.

What lives in *this* repo for the Audi target:

- `src/native/altscreen111-gen2/libaltscreen111_gen2.c` — the GEN2 hook. Build the
  Audi variant with:

  ```sh
  tools/build_altscreen111_mhi2q.sh          # -> build/libaltscreen111_mhi2q.so
  ```

  `-DALT111_TARGET_MHI2Q` selects a constructor-free, PLT-interposition build with
  1440×540 defaults and stream 111 on port 7111. The Škoda MU1440 build is
  unchanged.

Background on why MHI2Q is a separate target, and the offline firmware evidence:

- [`docs/research/AUDI_B9_MU1438_COMPATIBILITY_LEAD_2026-09-28.md`](../research/AUDI_B9_MU1438_COMPATIBILITY_LEAD_2026-09-28.md)
- [`docs/research/MU1438_MU1440_OFFLINE_COMPARISON_2026-09-28.md`](../research/MU1438_MU1440_OFFLINE_COMPARISON_2026-09-28.md)

> The session-key capture step is the one part that may need adaptation to your
> exact `libairplay` (see §7 of the deploy guide). Everything downstream of a
> captured key is implemented and host-tested.
