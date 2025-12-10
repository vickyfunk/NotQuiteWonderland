@tool
extends RefCounted

const SUPPORTED_FORMATS = ["png", "jpg", "jpeg", "bmp", "tga", "webp", "svg", "dds", "hdr"]

const TEXTURE_TYPES = {
	"basecolor": "albedo_texture",
	"albedo": "albedo_texture",
	"diffuse": "albedo_texture",
	"diff": "albedo_texture",
	"color": "albedo_texture",
	"metallic": "metallic_texture",
	"roughness": "roughness_texture",
	"rough": "roughness_texture",
	"normal": "normal_texture",
	"normalogl": "normal_texture",
	"normalgl": "normal_texture",
	"nor": "normal_texture",
	"height": "heightmap_texture",
	"heightmap": "heightmap_texture",
	"displacement": "heightmap_texture",
	"disp": "heightmap_texture",
	"ambientocclusion": "ao_texture",
	"ao": "ao_texture",
	"emission": "emission_texture"
}

static func generate_material(folder_path: String, force_overwrite: bool = false, output_folder: String = "", merge_mode: bool = false, apply_overrides: bool = false) -> Dictionary:
	folder_path = folder_path.rstrip("/")
	
	if not folder_path.begins_with("res://") and not folder_path.begins_with("user://"):
		return {"status": "error", "message": "Error: Path must be a valid res:// or user:// path: " + folder_path}
	
	var dir = DirAccess.open(folder_path)
	if not dir:
		return {"status": "error", "message": "Error: Could not open folder: " + folder_path}
	
	# Scan current folder and common texture subdirectories
	var scan_paths = [folder_path]
	if dir.dir_exists(folder_path.path_join("textures")):
		scan_paths.append(folder_path.path_join("textures"))
	
	# Group textures by their base name
	var material_sets = {}
	
	for scan_path in scan_paths:
		var scan_dir = DirAccess.open(scan_path)
		if not scan_dir:
			continue
			
		scan_dir.list_dir_begin()
		var file_name = scan_dir.get_next()
		while file_name != "":
			if not scan_dir.current_is_dir() and not file_name.ends_with(".import"):
				# Check if file format is supported
				var extension = file_name.get_extension().to_lower()
				if extension in SUPPORTED_FORMATS:
					var texture_info = _parse_texture_file(file_name)
					if texture_info:
						var base_name = texture_info.base_name
						var property = texture_info.property
						
						if not material_sets.has(base_name):
							material_sets[base_name] = {}
						
						if not material_sets[base_name].has(property):
							material_sets[base_name][property] = scan_path.path_join(file_name)
			file_name = scan_dir.get_next()
		scan_dir.list_dir_end()
	
	if material_sets.is_empty():
		return {"status": "error", "message": "Error: No texture files found in folder"}
	
	# Generate materials for each set
	var results = []
	var output_base = output_folder if not output_folder.is_empty() else folder_path.get_base_dir()
	
	for material_name in material_sets:
		var textures = material_sets[material_name]
		var output_path = output_base.path_join(material_name + ".tres")
		
		if FileAccess.file_exists(output_path) and not force_overwrite and not merge_mode:
			results.append({"status": "exists", "path": output_path, "textures": textures, "material_name": material_name})
		else:
			var result = _create_material_file(output_path, textures, merge_mode, apply_overrides)
			result["material_name"] = material_name
			results.append(result)
	
	if results.size() == 1:
		return results[0]
	else:
		return {"status": "multiple", "results": results}

static func _create_material_file(output_path: String, textures: Dictionary, merge_mode: bool = false, apply_overrides: bool = false) -> Dictionary:
	if not output_path.begins_with("res://") and not output_path.begins_with("user://"):
		return {"status": "error", "message": "Error: Output path must be a valid res:// or user:// path: " + output_path}
	
	var material = StandardMaterial3D.new()
	
	# In merge mode, load the existing material if it exists
	if merge_mode and FileAccess.file_exists(output_path):
		var existing_material = load(output_path)
		if existing_material and existing_material is StandardMaterial3D:
			material = existing_material.duplicate()
		else:
			return {"status": "error", "message": "Error: Existing file is not a valid StandardMaterial3D: " + output_path}
	
	# Apply textures with their specific properties
	const TEXTURE_PROPERTIES = {
		"albedo_texture": {"property": "albedo_texture"},
		"metallic_texture": {"property": "metallic_texture", "enable_if_new": {"metallic": 1.0}},
		"roughness_texture": {"property": "roughness_texture"},
		"normal_texture": {"property": "normal_texture", "enable": {"normal_enabled": true}},
		"heightmap_texture": {"property": "heightmap_texture", "enable": {"heightmap_enabled": true}},
		"ao_texture": {"property": "ao_texture", "enable": {"ao_enabled": true}},
		"emission_texture": {"property": "emission_texture", "enable": {"emission_enabled": true}}
	}
	
	var skipped_textures = []
	for texture_key in textures:
		if TEXTURE_PROPERTIES.has(texture_key):
			var texture = load(textures[texture_key])
			if texture:
				var props = TEXTURE_PROPERTIES[texture_key]
				material.set(props.property, texture)
				
				# Always enable these features when texture is present
				if props.has("enable"):
					for enable_prop in props.enable:
						material.set(enable_prop, props.enable[enable_prop])
				
				# Only set these in create/overwrite mode, not merge mode
				if not merge_mode and props.has("enable_if_new"):
					for enable_prop in props.enable_if_new:
						material.set(enable_prop, props.enable_if_new[enable_prop])
			else:
				skipped_textures.append(textures[texture_key])
	
	# Apply texture property overrides if requested
	if apply_overrides:
		if material.get("roughness_texture") != null:
		# if textures.has("roughness_texture"):
			material.set("roughness_texture_channel", BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE)
		if material.get("ao_texture") != null:
		# if textures.has("ao_texture"):
			material.set("ao_texture_channel", BaseMaterial3D.TEXTURE_CHANNEL_GRAYSCALE)
		if material.get("heightmap_texture") != null:
		# if textures.has("heightmap_texture"):
			material.set("heightmap_scale", 1.0)
	
	# Set the resource path before saving to ensure proper cache handling
	material.take_over_path(output_path)
	
	# Save the material
	var err = ResourceSaver.save(material, output_path)
	if err != OK:
		var error_msg = "Unknown error"
		match err:
			ERR_UNAUTHORIZED:
				error_msg = "Permission denied - ensure path is writable"
			ERR_FILE_CANT_WRITE:
				error_msg = "Cannot write to file - check permissions"
			ERR_FILE_BAD_PATH:
				error_msg = "Invalid path"
			_:
				error_msg = "Error code: " + str(err)
		return {"status": "error", "message": "Error: Failed to save material to " + output_path + " (" + error_msg + ")"}
	
	var action_type = "merged" if merge_mode else "created"
	var message = "Material " + action_type + " successfully: " + output_path
	if not skipped_textures.is_empty():
		message += "\n  Warning: Skipped unsupported texture formats:"
		for skipped in skipped_textures:
			message += "\n    - " + skipped.get_file()
	return {"status": "success", "message": message, "path": output_path}

# Parse a texture filename and extract base name and texture type
# Returns {base_name: String, property: String} or null if not recognized
static func _parse_texture_file(file_name: String) -> Dictionary:
	var base_name_lower = file_name.to_lower()
	var base_name_normalized = base_name_lower.replace("-", "").replace("_", "")
	
	# Find which texture type this file represents
	for texture_type in TEXTURE_TYPES:
		if base_name_normalized.contains(texture_type):
			var property = TEXTURE_TYPES[texture_type]
			
			# Extract the base name by finding the part before the texture type
			var base_name = _extract_base_name(file_name, texture_type)
			if base_name:
				return {"base_name": base_name, "property": property}
	
	return {}

# Extract the base material name from a texture filename
static func _extract_base_name(file_name: String, texture_type: String) -> String:
	var name_without_ext = file_name.get_basename()
	var lower_name = name_without_ext.to_lower()
	
	# Find the texture type in the normalized name
	var normalized = lower_name.replace("-", "").replace("_", "")
	var type_pos = normalized.find(texture_type)
	
	if type_pos == -1:
		return ""
	
	# Walk backwards from the type position to find the last separator in the original name
	var char_count = 0
	for i in range(lower_name.length()):
		var c = lower_name[i]
		if c != "_" and c != "-":
			char_count += 1
			if char_count > type_pos:
				# Found the position where texture type starts
				# Now walk back to find the last separator
				for j in range(i - 1, -1, -1):
					if lower_name[j] == "_" or lower_name[j] == "-":
						return name_without_ext.substr(0, j)
				break
	
	return name_without_ext
