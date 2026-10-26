extends RefCounted
## Collapse opaque, untextured material palettes into vertex colors. Geometry,
## normals, UVs, transparent surfaces and material lighting settings are retained.
## Cached per mesh/material combination; authored resources are never modified.

var _cache: Dictionary = {}
var _materials: Dictionary = {}

func optimize(source: MeshInstance3D) -> void:
	if not source.mesh is ArrayMesh or source.skin != null or source.material_overlay != null:
		return
	var original := source.mesh as ArrayMesh
	if original.get_blend_shape_count() > 0 or original.get_surface_count() < 2:
		return
	var materials: Array = []
	for surface in original.get_surface_count():
		materials.append(source.get_active_material(surface))
	var key: Array = [original, materials]
	if not _cache.has(key):
		_cache[key] = _merge(original, materials)
	var optimized: ArrayMesh = _cache[key]
	if optimized == original: return
	for surface in original.get_surface_count():
		source.set_surface_override_material(surface, null)
	source.material_override = null
	source.mesh = optimized

func _material_key(material: Material) -> Array:
	if _materials.has(material): return _materials[material]
	var key: Array = []
	if material is StandardMaterial3D and material.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and material.albedo_texture == null and not material.vertex_color_use_as_albedo and material.next_pass == null:
		for property: Dictionary in material.get_property_list():
			var name: String = property.name
			if not property.usage & PROPERTY_USAGE_STORAGE: continue
			if name in ["resource_name", "resource_path", "resource_local_to_scene", "script", "albedo_color", "vertex_color_use_as_albedo", "vertex_color_is_srgb"]: continue
			key.append(material.get(name))
	_materials[material] = key
	return key

func _merge(original: ArrayMesh, materials: Array) -> ArrayMesh:
	var groups: Dictionary = {}
	for surface in original.get_surface_count():
		var key := _material_key(materials[surface])
		if key.is_empty() or original.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
			key = [surface]
		else:
			# Only concatenate surfaces with the same vertex attribute layout.
			key = [key, original.surface_get_format(surface) & ((1 << Mesh.ARRAY_MAX) - 1)]
		if not groups.has(key): groups[key] = []
		groups[key].append(surface)
	if groups.size() == original.get_surface_count(): return original
	var result := ArrayMesh.new()
	var raw: Array = original.get("_surfaces")
	for group: Array in groups.values():
		if group.size() == 1:
			var surface: int = group[0]
			result.add_surface_from_arrays(original.surface_get_primitive_type(surface), original.surface_get_arrays(surface), [], _lods(raw[surface]))
			result.surface_set_material(result.get_surface_count() - 1, materials[surface])
			continue
		var joined: Array = []
		joined.resize(Mesh.ARRAY_MAX)
		var pieces: Array = []
		var offset := 0
		var thresholds: Array[float] = []
		for surface: int in group:
			var arrays := original.surface_get_arrays(surface)
			var count: int = arrays[Mesh.ARRAY_VERTEX].size()
			var colors := PackedColorArray()
			colors.resize(count)
			colors.fill(materials[surface].albedo_color)
			arrays[Mesh.ARRAY_COLOR] = colors
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				indices.resize(count)
				for index in count: indices[index] = index
			var lods := _lods(raw[surface])
			for threshold: float in lods:
				if threshold not in thresholds: thresholds.append(threshold)
			pieces.append({"offset":offset,"indices":indices.duplicate(),"lods":lods})
			for index in indices.size(): indices[index] += offset
			arrays[Mesh.ARRAY_INDEX] = indices
			for attribute in Mesh.ARRAY_MAX:
				if arrays[attribute] == null: continue
				if joined[attribute] == null:
					joined[attribute] = arrays[attribute].duplicate()
				else:
					joined[attribute].append_array(arrays[attribute])
			offset += count
		# Keep up to four conservative LOD transitions. A surface only simplifies
		# after its original threshold, retaining at least the authored detail.
		thresholds.sort()
		var combined_lods := {}
		var step := maxi(1, ceili(float(thresholds.size()) / 4.0))
		for index in range(step - 1, thresholds.size(), step):
			var threshold := thresholds[index]
			var combined := PackedInt32Array()
			for piece: Dictionary in pieces:
				var selected: PackedInt32Array = piece.indices
				var selected_threshold := 0.0
				for distance: float in piece.lods:
					if distance <= threshold and distance > selected_threshold:
						selected = piece.lods[distance]
						selected_threshold = distance
				selected = selected.duplicate()
				for vertex in selected.size(): selected[vertex] += piece.offset
				combined.append_array(selected)
			combined_lods[threshold] = combined
		result.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, joined, [], combined_lods)
		var material: StandardMaterial3D = materials[group[0]].duplicate()
		material.albedo_color = Color.WHITE
		material.vertex_color_use_as_albedo = true
		material.vertex_color_is_srgb = true
		result.surface_set_material(result.get_surface_count() - 1, material)
	return result

func _lods(surface: Dictionary) -> Dictionary:
	var result := {}
	var raw: Array = surface.get("lods", [])
	var wide: bool = int(surface.vertex_count) > 65536
	for index in range(0, raw.size(), 2):
		var bytes: PackedByteArray = raw[index + 1]
		var indices := PackedInt32Array()
		var stride := 4 if wide else 2
		indices.resize(bytes.size() / stride)
		for vertex in indices.size():
			indices[vertex] = bytes.decode_u32(vertex * stride) if wide else bytes.decode_u16(vertex * stride)
		result[float(raw[index])] = indices
	return result
