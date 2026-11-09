# ADR-0011: Original Asset and Copyright Policy

- **Status:** Accepted
- **Date:** 2026-11-09
- **Deciders:** Technical Director, Lead Architect

---

## Context
ShadowCraft 2D takes conceptual and mechanical inspiration from two renowned franchises:
- *Shadow Fight 2* (martial arts dojo progression, shadow aesthetic, tactical 2D pacing).
- *Minecraft* (weapon taxonomy, material tiers: Wood, Stone, Iron, Diamond, Netherite).

To avoid copyright infringement, trademark disputes, and ethical compromises, the game must be 100% original in assets, code, branding, and storytelling.

## Decision
We enforce a strict **Original Asset and Copyright Policy**:
1. **Absolute Prohibition of Asset Extraction:**
   - Under no circumstances shall any sprite, texture, animation, sound effect, music track, UI graphic, font, map, or 3D mesh from *Shadow Fight 2*, *Minecraft*, or any third-party game be imported, copied, traced, or adapted.
2. **Original IP Creation:**
   - Characters Kai (Purple Shadow Disciple) and Razen (Crimson Warlord) are fully original characters with distinct silhouettes, anatomical proportions, clothing, and backstories.
   - All weapon sprites, combat VFX, audio, and dojo backgrounds must be original works created specifically for ShadowCraft 2D.
3. **Conceptual Borrowing Boundaries:**
   - Game mechanics (e.g., active hitboxes, parry windows, martial dojos, material progression tiers) are recognized industry-standard gameplay tropes that are not subject to copyright. Their concrete expression (visual art, sound, narrative, precise code) must be 100% bespoke.
4. **Asset Provenance & Tracking:**
   - Every asset added to the project must be cataloged in `docs/ASSET_GUIDELINES.md` with recorded origin, creator/license, and verification date.

## Alternatives Considered
- **Using "Royalty Free" Minecraft/SF2 fan packs:** High risk of containing copyrighted intellectual property or dubious licensing. Strictly rejected.
- **Placeholder rips from old project:** Prohibited to ensure a completely clean, uncompromised legal and artistic slate.

## Consequences
- **Positive:** Complete commercial viability, 100% copyright ownership, distinct and memorable visual brand identity.
- **Negative:** Requires creating all 2D assets from scratch or using fully verified, original creation pipelines.

