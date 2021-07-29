/**
 The type of media of a given book. This enum specifically does not involve
 DRM formats.
 */
typedef NS_ENUM(NSInteger, NYPLBookContentType) {
  NYPLBookContentTypeEPUB,
  NYPLBookContentTypeAudiobook,
  NYPLBookContentTypePDF,
  NYPLBookContentTypeUnsupported
};


/// Tries to determines the book content type based on the acquisition MIME
/// type.
///
/// Note that this determination may prove impossible because certain
/// MIME types are used for multiple media content types. (e.g. the Adobe
/// MIME type can be used for many media types.) In addition MIME types can
/// also be nested (see @p NYPLOPDSAcquisitionPath::supportedSubtypesForType:).
///
/// @deprecated Therefore, usage of this api is discouraged.
///
/// @param string The MIME type of the acquisition type. For possible values
/// see @p NYPLOPDSAcquisitionPath.
///
NYPLBookContentType NYPLBookContentTypeFromMIMEType(NSString *string);
