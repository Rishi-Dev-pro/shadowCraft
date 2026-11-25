# Kai artwork review

**Static visual match passed. Full skeletal-ready artwork remains blocked.**

The master is `assets/characters/kai_v2/animations/idle_signature/idle_01.png`, the right-facing painted combat stance used by the original SpriteFrames. The original turnaround, painted idle, forward and backward walks, run, crouch, jump, landing, jab, cross, heavy punch, front kick, and the in-game comparison were reviewed for pose and surface coverage.

The package contains 19 cropped RGBA layers and their registration coordinates. Reassembling the exported layers at their recorded origins preserves all 65,114 pixels with visible alpha, including their RGB and alpha channels. The 512 × 512 preview uses the original recorded orientation and ground line. The narrow edge underlaps use adjacent texture from the same part. They do not replace the larger occluded surfaces.

The missing artwork is an unoccluded chest and near sleeve beneath the near forearm, the far inner shoulder and sleeve, and the waist and hip folds beneath the belt, front flap, and purple sash. The motion references expose parts of these surfaces at different angles and poses. They do not supply a verified matching underlay in the approved neutral pose. A layered version of the painted combat artwork, or matching paint for those covered surfaces, is required for full rigging acceptance. The registered PNGs are a static reconstruction and are pending that artwork.

Only the isolated experimental artwork directory was created. No animation, rig scene, SpriteFrames, or gameplay was changed.
