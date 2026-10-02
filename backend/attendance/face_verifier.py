import sys
import json

import face_recognition


def verify_face(image_path, registered_encodings):
    # --------------------------------------------------------
    # Load live face image
    # --------------------------------------------------------

    image = face_recognition.load_image_file(image_path)

    # --------------------------------------------------------
    # Detect face
    # --------------------------------------------------------

    face_locations = face_recognition.face_locations(image)

    if len(face_locations) == 0:
        return {
            'success': False,
            'verified': False,
            'error': 'No face detected'
        }

    if len(face_locations) > 1:
        return {
            'success': False,
            'verified': False,
            'error': 'Multiple faces detected'
        }

    # --------------------------------------------------------
    # Generate live face encoding
    # --------------------------------------------------------

    encodings = face_recognition.face_encodings(
        image,
        face_locations
    )

    if not encodings:
        return {
            'success': False,
            'verified': False,
            'error': 'Could not generate face encoding'
        }

    live_encoding = encodings[0]

    # --------------------------------------------------------
    # Compare live face with registered faces
    # --------------------------------------------------------

    best_distance = None
    best_view = None

    for view_name, encoding in registered_encodings.items():

        distance = face_recognition.face_distance(
            [encoding],
            live_encoding
        )[0]

        if best_distance is None or distance < best_distance:
            best_distance = float(distance)
            best_view = view_name

    # --------------------------------------------------------
    # Face verification threshold
    # --------------------------------------------------------

    tolerance = 0.6

    verified = (
        best_distance is not None
        and best_distance <= tolerance
    )

    # --------------------------------------------------------
    # Return result
    # --------------------------------------------------------

    return {
        'success': True,
        'verified': verified,
        'matched_view': best_view,
        'distance': best_distance,
        'tolerance': tolerance
    }


if __name__ == '__main__':

    # --------------------------------------------------------
    # Required arguments
    #
    # 1. Image path
    # 2. Registered face encodings as JSON
    # --------------------------------------------------------

    if len(sys.argv) != 3:

        print(json.dumps({
            'success': False,
            'verified': False,
            'error': (
                'Image path and registered '
                'encodings are required'
            )
        }))

        sys.exit(1)

    image_path = sys.argv[1]

    try:
        registered_encodings = json.loads(
            sys.argv[2]
        )

    except json.JSONDecodeError:

        print(json.dumps({
            'success': False,
            'verified': False,
            'error': 'Invalid registered face data'
        }))

        sys.exit(1)

    result = verify_face(
        image_path,
        registered_encodings
    )

    print(json.dumps(result))