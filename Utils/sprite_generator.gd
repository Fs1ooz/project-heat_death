@tool
extends SubViewport

@export var genera_spritesheet: bool = true
@export var genera_poligoni: bool = true
@export var rows: int = 6
@export var columns: int = 10
@export var model: Node3D
@export var genera_ora: bool = false:
	set(value):
		if Engine.is_editor_hint() and value == true:
			_genera_sprite()
		genera_ora = false

@export var save_path: String = "res://Assets/Images/Spritesheets/meteoroid_1_atlas.png"
@export var polygons_save_path: String = "res://Assets/meteoroid_1_polygons.tres"
@export var alpha_threshold: float = 0.1
@export var simplify_epsilon: float = 4.0

func _genera_sprite() -> void:
	if not model:
		push_error("ERRORE: Assegna il modello nell'Inspector!")
		return

	var angle: float = 0.0
	var current_image: Image = get_texture().get_image()
	var format: Image.Format = current_image.get_format()
	var total_width: int = size.x * columns
	var total_height: int = size.y * rows
	var result: Image = Image.create_empty(total_width, total_height, false, format)
	var all_polygons: Array[PackedVector2Array] = []
	var frame_size: Vector2 = Vector2(size)
	var offset: Vector2 = -frame_size / 2.0

	print("Inizio generazione (%d frame)..." % (rows * columns))

	for r: int in range(rows):
		for c: int in range(columns):
			model.rotation.y = angle
			await RenderingServer.frame_post_draw
			var frame_img: Image = get_texture().get_image()

			# --- Blit nella spritesheet (solo se abilitato) ---
			if genera_spritesheet:
				var dest_x: int = c * size.x
				var dest_y: int = r * size.y
				result.blit_rect(frame_img, Rect2i(Vector2i.ZERO, size), Vector2i(dest_x, dest_y))

			# --- Genera poligono (solo se abilitato) ---
			if genera_poligoni:
				var bmp: BitMap = BitMap.new()
				bmp.create_from_image_alpha(frame_img, alpha_threshold)
				var polys: Array[PackedVector2Array] = bmp.opaque_to_polygons(Rect2(Vector2.ZERO, frame_img.get_size()), simplify_epsilon)
				var best: PackedVector2Array = PackedVector2Array()
				for p: PackedVector2Array in polys:
					if p.size() > best.size():
						best = p
				var centered: PackedVector2Array = PackedVector2Array()
				for v: Vector2 in best:
					centered.append(v + offset)
				all_polygons.append(centered)

			angle += TAU / float(rows * columns)

	# --- Salva spritesheet ---
	if genera_spritesheet:
		var error: Error = result.save_png(save_path)
		if error == OK:
			print("SUCCESSO: Spritesheet salvato in: ", ProjectSettings.globalize_path(save_path))
		else:
			push_error("Errore durante il salvataggio della spritesheet.")

	# --- Salva poligoni ---
	if genera_poligoni:
		var data: FramePolygonData = FramePolygonData.new()
		data.polygons = all_polygons
		print("Poligoni generati: ", all_polygons.size())
		for i: int in min(3, all_polygons.size()):
			print("  Frame %d: %d vertici" % [i, all_polygons[i].size()])
		var poly_error: Error = ResourceSaver.save(data, polygons_save_path)
		if poly_error == OK:
			print("SUCCESSO: Poligoni salvati in: ", ProjectSettings.globalize_path(polygons_save_path))
			var total_verts: int = 0
			for p: PackedVector2Array in all_polygons:
				total_verts += p.size()
			print("  → %d frame, media vertici: %.1f" % [
				all_polygons.size(),
				float(total_verts) / all_polygons.size()
			])
		else:
			push_error("Errore durante il salvataggio dei poligoni.")
