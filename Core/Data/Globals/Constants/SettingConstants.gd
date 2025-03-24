extends Node

# ===================== SETTING CONSTANTS =====================
# Constants for setting up the game

# Window/Viewport Constants
const WINDOW_REFERENCE_WIDTH = 1920
const WINDOW_REFERENCE_HEIGHT = 1080
const WINDOW_REFERENCE_RESOLUTION = Vector2(WINDOW_REFERENCE_WIDTH, WINDOW_REFERENCE_HEIGHT)
const WINDOW_ASPECT_RATIO = WINDOW_REFERENCE_WIDTH / WINDOW_REFERENCE_HEIGHT
const RESOLUTIONS = [
    Vector2i(1280, 720),
    Vector2i(1366, 768),
    Vector2i(1600, 900),
    Vector2i(1920, 1080),
    Vector2i(2560, 1440),
    Vector2i(3345, 2234)
]

# UI Constants
const UI_MINIMUM_SCALE = 1.0

# Map Constants
const COLLISION_BATCH_SIZE = 10
const PORTAL_BATCH_SIZE = 10
const COMPONENT_PROCESSING_WAIT_TIME = 0.5
