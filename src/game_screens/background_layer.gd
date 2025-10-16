extends CanvasLayer

@onready var video: VideoStreamPlayer = $Video
@onready var image: TextureRect = $Image

func _ready() -> void:
    if ResourceLoader.exists("res://assets/scifi.ogv"):
        var video_stream: VideoStream = load("res://assets/scifi.ogv")
        video.stream = video_stream
        video.play()
        image.hide()
    else:
        video.hide()