# disabled_mods — archive, NOT loaded

Nothing in this directory is loaded by the running server. The engine loads
content from `main/` (and `.pk3`s placed there); these files live outside that
load path on purpose.

This is a parts bin / reference archive of mods that were evaluated, replaced,
or shelved. Kept on disk for reference, not because they run. Notable items:

- `zz_ranking_final_modif.pk3` — Airborne (Sor) per-session kill-tier ranking
  with weapon bonuses. Per-round only; no cross-map persistence. Superseded by
  the custom mods in `main/global/feho/`.
- `zz_Anticham_v5.pk3` — old Anticham anti-cheat. Superseded by the custom
  `global/feho/anticheat.scr`.
- `zz_veersmods.pk3`, `zz_vehicules.pk3`, `zz_squadmaker_maps.pk3`,
  `zz_server-auto_team_balancer_v0321_b.pk3`, etc. — evaluated, not in use.

To actually enable one of these, move/extract it into `main/` — editing it here
does nothing. If an item is confirmed dead for good, delete it; git history is
the archive of last resort.
