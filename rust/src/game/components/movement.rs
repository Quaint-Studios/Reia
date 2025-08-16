use bevy::prelude::{ Component, Vec3 };

#[derive(Component, Debug)]
pub struct Position(pub Vec3);

#[derive(Component, Debug)]
pub struct Rotation(pub Vec3);

#[derive(Component, Debug)]
pub struct Velocity(pub Vec3);

#[derive(Component, Debug)]
pub struct Speed(pub f32);
