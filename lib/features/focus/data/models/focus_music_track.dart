/// Bundled background-music track for an active Focus session.
///
/// The catalog maps to the real, bundled Focus Audio assets
/// (`assets/audio/focus_*.mp3`). Selection is per-user, OFF by default
/// (index -1), and cycles OFF → Calm → Ambient → Energy when a track is
/// picked from the HUD.
class FocusMusicTrack {
  const FocusMusicTrack({
    required this.id,
    required this.title,
    required this.assetPath,
  });

  final String id;

  /// User-facing name shown in the HUD selector.
  final String title;

  /// Flutter asset-bundle path (also resolvable by the native player).
  final String assetPath;

  static const calm = FocusMusicTrack(
    id: 'calm',
    title: 'Calm',
    assetPath: 'assets/audio/focus_calm.mp3',
  );

  static const ambient = FocusMusicTrack(
    id: 'ambient',
    title: 'Ambient',
    assetPath: 'assets/audio/focus_ambient.mp3',
  );

  static const energy = FocusMusicTrack(
    id: 'energy',
    title: 'Energy',
    assetPath: 'assets/audio/focus_energy.mp3',
  );

  /// The full Focus Music catalog in OFF → Calm → Ambient → Energy order.
  static const List<FocusMusicTrack> tracks = [calm, ambient, energy];
}
