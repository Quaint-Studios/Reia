use crate::state::world_state::WorldState;
use std::sync::Arc;

/// A high-performance math module. Because we are iterating over a
/// `DashMap`, this math executes in microseconds and won't block
/// Tokio from receiving network packets or Godot from processing frames.
pub struct SpatialMath;

impl SpatialMath {
    /// Fast distance check. Used for proximity interactions (e.g., looting, talking).
    /// Returns a list of network IDs within the radius.
    pub fn query_radius(
        state: &Arc<WorldState>,
        origin_x: f32,
        origin_y: f32,
        origin_z: f32,
        radius: f32
    ) -> Vec<i64> {
        let mut hits = Vec::new();
        let radius_sq = radius * radius; // Compare squared distance to avoid expensive sqrt()

        // Iterate lock-free over the DashMap
        for entry in state.players.iter() {
            let pd = entry.value();

            let dx = pd.x - origin_x;
            let dy = pd.y - origin_y;
            let dz = pd.z - origin_z;

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
        origin_x: f32,
        origin_y: f32,
        origin_z: f32,
        dir_x: f32,
        dir_y: f32,
        dir_z: f32,
        radius: f32,
        angle_degrees: f32
    ) -> Vec<i64> {
        let mut hits = Vec::new();
        let radius_sq = radius * radius;

        // Convert angle to radians and get cosine of half the angle
        // The dot product of two normalized vectors gives the cosine of the angle between them.
        let half_angle_rad = (angle_degrees / 2.0).to_radians();
        let cos_half_angle = half_angle_rad.cos();

        // Ensure direction vector is normalized
        let dir_len = (dir_x * dir_x + dir_y * dir_y + dir_z * dir_z).sqrt();
        if dir_len == 0.0 {
            return hits;
        } // Avoid division by zero
        let (nx, ny, nz) = (dir_x / dir_len, dir_y / dir_len, dir_z / dir_len);

        for entry in state.players.iter() {
            let pd = entry.value();

            let dx = pd.x - origin_x;
            let dy = pd.y - origin_y;
            let dz = pd.z - origin_z;

            let dist_sq = dx * dx + dy * dy + dz * dz;

            // Broad-phase distance cull
            if dist_sq > radius_sq || dist_sq == 0.0 {
                continue; // Too far away or it's the caster themselves
            }

            // Narrow-phase Dot Product cull
            let dist = dist_sq.sqrt();
            let p_nx = dx / dist;
            let p_ny = dy / dist;
            let p_nz = dz / dist;

            let dot_product = nx * p_nx + ny * p_ny + nz * p_nz;

            if dot_product >= cos_half_angle {
                hits.push(*entry.key());
            }
        }

        hits
    }
}
