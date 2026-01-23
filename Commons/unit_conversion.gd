extends Node

# 1 Unità Astronomica in chilometri (valore reale)
const AU_IN_KM: float = 149_597_870.7

# Il tuo fattore di scala globale (da km a pixel di gioco)
# Se vuoi cambiare quanto è grande l'universo, cambi solo questo numero qui.
const GAME_SCALE: float = 0.001

# Converte UA -> Pixel di gioco (per posizionare gli oggetti)
func au_to_pixels(au: float) -> float:
	return au * AU_IN_KM * GAME_SCALE

# Converte Pixel di gioco -> UA (per la UI o i log)
func pixels_to_au(pixels: float) -> float:
	if pixels == 0: return 0.0
	return pixels / (AU_IN_KM * GAME_SCALE)

# Converte UA -> Km (per visualizzazioni testuali realistiche)
func au_to_km(au: float) -> float:
	return au * AU_IN_KM

# Converte Pixel di gioco -> Km
func pixels_to_km(pixels: float) -> float:
	return pixels / GAME_SCALE
