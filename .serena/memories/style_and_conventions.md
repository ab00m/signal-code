# Style And Conventions
- Godot project using GDScript `.gd`, scene `.tscn`, and resource `.tres` files.
- Keep Godot-generated `.uid` files tracked when present; they are part of Godot 4 resource identity handling.
- Prefer editing project settings through Godot editor when practical; `project.godot` comments note the format is best edited via the editor UI.
- Preserve existing directory organization: scene-specific scripts live near scenes, shared state scripts live in `scripts/`, reusable resources in `resources/`.