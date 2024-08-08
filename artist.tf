data "spotify_search_track" "rahman" {
  artist = "A.R.Rahman"
}
resource "spotify_playlist" "rahman" {
    name = "rahman"
    tracks = [data.spotify_search_track.rahman.tracks[1].id,
    data.spotify_search_track.rahman.tracks[2].id,
    data.spotify_search_track.rahman.tracks[3].id,
    data.spotify_search_track.rahman.tracks[4].id,
    data.spotify_search_track.rahman.tracks[6].id]
}