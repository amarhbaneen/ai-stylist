import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:wardrobe_domain/wardrobe_domain.dart';

import '../logging/app_logger.dart';

enum MediaSourceKind { camera, gallery }

/// Lets the user choose one photo. Only the permission for the chosen source
/// is involved, and only when the user taps it (REQUIREMENTS §6.2).
abstract interface class MediaPicker {
  /// Path of a temporary copy of the chosen photo, or [CancelledFailure].
  Future<Result<String>> pick(MediaSourceKind source);

  /// Android may kill the app while the camera or gallery is open; the result
  /// is then delivered on the next launch. Returns any such recovered path.
  Future<String?> recoverLostPick();
}

/// [MediaPicker] backed by `image_picker`.
///
/// - Android: the system Photo Picker and camera intent need no runtime
///   permission declared by this app.
/// - iOS: `requestFullMetadata: false` avoids the photo-library permission
///   prompt; the camera still shows the system prompt on first use.
final class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker([ImagePicker? picker])
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Result<String>> pick(MediaSourceKind source) async {
    try {
      final file = await _picker.pickImage(
        source: switch (source) {
          MediaSourceKind.camera => ImageSource.camera,
          MediaSourceKind.gallery => ImageSource.gallery,
        },
        requestFullMetadata: false,
      );
      if (file == null) return const Failure(CancelledFailure());
      return Success(file.path);
    } on PlatformException catch (e) {
      AppLogger.error('Picker failed: ${e.code}', e);
      return Failure(mapPickerError(e));
    }
  }

  @override
  Future<String?> recoverLostPick() async {
    try {
      final response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      final files = response.files;
      return (files == null || files.isEmpty) ? null : files.first.path;
    } on PlatformException catch (e) {
      AppLogger.error('Could not recover lost pick', e);
      return null;
    }
  }
}

/// Maps `image_picker` error codes to typed failures.
AppFailure mapPickerError(PlatformException e) => switch (e.code) {
  'camera_access_denied' ||
  'photo_access_denied' ||
  'camera_access_restricted' ||
  'photo_access_restricted' => PermissionDeniedFailure(
    'Access was denied',
    cause: e,
  ),
  'no_available_camera' => UnsupportedImageFailure(
    'No camera is available on this device',
    cause: e,
  ),
  'invalid_image' => UnsupportedImageFailure(
    'That file is not a supported image',
    cause: e,
  ),
  _ => StorageFailure('Could not get the photo (${e.code})', cause: e),
};
