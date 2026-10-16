# Video Processing Scripts

A collection of Bash scripts for common video and audio processing tasks using FFmpeg.

## Requirements

* Linux
* Bash
* FFmpeg

## Scripts

### `add_audio_tracks.sh`

Adds background audio tracks to a video.

```bash
./add_audio_tracks.sh INPUT_VIDEO OUTPUT_VIDEO AUDIO1 [AUDIO2 ...]
```

Example:

```bash
./add_audio_tracks.sh input.mkv output.mkv music1.mp3 music2.mp3
```

### `cut_video_from.sh`

Cuts a video from the specified timestamp to the end.

```bash
./cut_video_from.sh INPUT_VIDEO OUTPUT_VIDEO START
```

Example:

```bash
./cut_video_from.sh input.mkv output.mkv 00:12:30
```

### `cut_video_from_to.sh`

Removes a specified interval from a video.

```bash
./cut_video_from_to.sh INPUT_VIDEO OUTPUT_VIDEO START END
```

Example:

```bash
./cut_video_from_to.sh input.mkv output.mkv 00:12:30 00:17:30
```

## Usage

Make the scripts executable:

```bash
chmod +x add_audio_tracks.sh cut_video_from.sh cut_video_from_to.sh
```

Run a script without arguments to display its usage instructions, if supported.

## Notes

* The scripts use FFmpeg for media processing.
* Video streams are copied without re-encoding wherever supported.
* Stream-copy cuts may not be frame-accurate because of keyframe placement.
* Keep backups of your original files.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

