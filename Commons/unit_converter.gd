class_name UnitConverter

const AU_IN_KM: float = 149_597_870.7
const GAME_SCALE: float = 0.01

static func au_to_pixels(au: float) -> float:
	return au * AU_IN_KM * GAME_SCALE

static func pixels_to_au(pixels: float) -> float:
	if pixels == 0: return 0.0
	return pixels / (AU_IN_KM * GAME_SCALE)

static func au_to_km(au: float) -> float:
	return au * AU_IN_KM

static func pixels_to_km(pixels: float) -> float:
	return pixels / GAME_SCALE
