use bevy::ecs::resource::Resource;
use rand::{ Rng, RngCore, SeedableRng, rngs::SmallRng };

/// Deterministic / fast RNG wrapper for gameplay needs (crit rolls, etc.)
/// - Uses rand::rngs::SmallRng (small, fast, portable)
/// - Exposes both seeded and entropy-based construction
#[derive(Resource)]
pub struct GameRng(pub SmallRng);

impl GameRng {
    /// Create from explicit seed (deterministic across runs)
    #[inline]
    pub fn from_seed(seed: u64) -> Self {
        Self(SmallRng::seed_from_u64(seed))
    }

    /// Create from system entropy (non-deterministic)
    #[inline]
    pub fn from_entropy() -> Self {
        let rng = match SmallRng::try_from_os_rng() {
            Ok(res) => res,
            Err(_err) => SmallRng::seed_from_u64(0), // fallback to a default seed
        };
        Self(rng)
    }

    /// Default: from entropy. Use `GameRng::from_seed` in tests or lockstep.
    #[inline]
    pub fn default() -> Self {
        Self::from_entropy()
    }

    /// 0..=10000 basis points (useful for crit checks stored in basis points)
    #[inline]
    pub fn next_u16_in_basis(&mut self) -> u16 {
        // reduce a u32 to 0..=10000; uniform enough for gameplay uses
        (self.0.next_u32() % 10_001) as u16
    }

    /// 0.0 .. 1.0 float
    #[inline]
    pub fn next_f32(&mut self) -> f32 {
        self.0.random::<f32>()
    }

    /// Convenience: next u32
    #[inline]
    pub fn next_u32(&mut self) -> u32 {
        self.0.next_u32()
    }
}

impl Default for GameRng {
    fn default() -> Self {
        GameRng::from_entropy()
    }
}
