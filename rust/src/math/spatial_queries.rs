use crate::state::world_state::WorldState;
use godot::builtin::Vector3;
use std::sync::Arc;

/// A high-performance math module. Because we are iterating over a
/// `DashMap`, this math executes in microseconds and won't block
/// Tokio from receiving network packets or Godot from processing frames.
pub struct SpatialMath;

impl SpatialMath {
    /// Fast distance check. Used for proximity interactions (e.g., looting, talking).
    /// Returns a list of network IDs within the radius.
    pub fn query_radius(state: &Arc<WorldState>, origin: Vector3, radius: f32) -> Vec<i64> {
        let mut hits = Vec::new();
        let radius_sq = radius * radius; // Compare squared distance to avoid expensive sqrt()

        // Iterate lock-free over the DashMap
        for entry in state.players.iter() {
            let pd = entry.value();

            let dx = pd.x - origin.x;
            let dy = pd.y - origin.y;
            let dz = pd.z - origin.z;

            let dist_sq = dx * dx + dy * dy + dz * dz;
            if dist_sq <= radius_sq {
                hits.push(*entry.key());
            }
        }

        hits
    }

    /// Cone query using Dot Products. Crucial for directional AoE attacks
    /// (e.g., Dragon's Breath, Cleave).
    pub fn query_cone(
        state: &Arc<WorldState>,
        origin: Vector3,
        direction: Vector3,
        radius: f32,
        angle_degrees: f32,
    ) -> Vec<i64> {
        let mut hits = Vec::new();
        let radius_sq = radius * radius;

        // Convert angle to radians and get cosine of half the angle
        // The dot product of two normalized vectors gives the cosine of the angle between them.
        let half_angle_rad = (angle_degrees / 2.0).to_radians();
        let cos_half_angle = half_angle_rad.cos();

        // Ensure direction vector is normalized
        let dir_len_sq = direction.length_squared();
        if dir_len_sq == 0.0 {
            return hits;
        } // Avoid division by zero
        let dir_normalized = direction.normalized();

        for entry in state.players.iter() {
            let pd = entry.value();

            let dx = pd.x - origin.x;
            let dy = pd.y - origin.y;
            let dz = pd.z - origin.z;

            let dist_sq = dx * dx + dy * dy + dz * dz;

            // Broad-phase distance cull
            if dist_sq > radius_sq || dist_sq == 0.0 {
                continue; // Too far away or it's the caster themselves
            }

            // Narrow-phase Dot Product cull
            let dist = dist_sq.sqrt();
            let target_dir = Vector3::new(dx / dist, dy / dist, dz / dist);

            let dot_product = dir_normalized.dot(target_dir);

            if dot_product >= cos_half_angle {
                hits.push(*entry.key());
            }
        }

        hits
    }
}
