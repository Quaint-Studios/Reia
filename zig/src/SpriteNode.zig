const std = @import("std");
const Godot = @import("godot");
const Vec2 = Godot.Vector2;
const Sprite = struct {
    pos: Vec2,
    vel: Vec2,
    scale: Vec2,
    gd_sprite: Godot.Sprite2D,
};
const Self = @This();
pub usingnamespace Godot.Control;
base: Godot.Control,

sprites: std.ArrayList(Sprite) = undefined,

pub fn newSpritesNode() *Self {
    var self = Godot.create(Self);
    self.example_node = null;
}

pub fn _ready(self: *Self) void {
    if (Godot.Engine.getSingleton().is_editor_hint()) return;

    self.sprites = std.ArrayList(Sprite).init(Godot.general_allocator);
    const rnd = Godot.initRandomNumberGenerator();
    defer _ = Godot.unreference(rnd);

    const resource_loader = Godot.ResourceLoader.getSingleton();
    const tex = resource_loader.load("res://textures/logo.png", "", Godot.ResourceLoader.CACHE_MODE_REUSE);
    defer _ = Godot.unreference(tex.?);
    const sz = self.get_parent_area_size();

    for (0..10000) |_| {
        const s: f32 = @floatCast(rnd.randf_range(0.1, 0.2));
        const spr = Sprite{
            .pos = Vec2.new(@floatCast(rnd.randf_range(0, sz.x)), @floatCast(rnd.randf_range(0, sz.y))),
            .vel = Vec2.new(@floatCast(rnd.randf_range(-1000, 1000)), @floatCast(rnd.randf_range(-1000, 1000))),
            .scale = Vec2.set(s),
            .gd_sprite = Godot.initSprite2D(),
        };
        spr.gd_sprite.set_texture(tex);
        spr.gd_sprite.set_rotation(rnd.randf_range(0, 3.14));
        spr.gd_sprite.set_scale(spr.scale);
        self.add_child(spr.gd_sprite, false, Godot.Node.INTERNAL_MODE_DISABLED);
        self.sprites.append(spr) catch unreachable;
    }
}

pub fn _exit_tree(self: *Self) void {
    self.sprites.deinit();
}

pub fn _physics_process(self: *Self, delta: f64) void {
    const sz = self.get_parent_area_size(); //get_size();

    for (self.sprites.items) |*spr| {
        const pos = spr.pos.add(spr.vel.scale(@floatCast(delta)));
        const spr_size = spr.gd_sprite.get_rect().get_size().mul(spr.gd_sprite.get_scale());

        if (pos.x <= spr_size.x / 2) {
            spr.vel.x = @abs(spr.vel.x);
        } else if (pos.x >= sz.x - spr_size.x / 2) {
            spr.vel.x = -@abs(spr.vel.x);
        }
        if (pos.y <= spr_size.y / 2) {
            spr.vel.y = @abs(spr.vel.y);
        } else if (pos.y >= sz.y - spr_size.y / 2) {
            spr.vel.y = -@abs(spr.vel.y);
        }
        spr.pos = pos;
        spr.gd_sprite.set_position(spr.pos);
    }
}
