import sys
import json
import face_recognition


def encode_face(image_path):
    image = face_recognition.load_image_file(image_path)

    face_locations = face_recognition.face_locations(image)

    if len(face_locations) == 0:
        return {
            'success': False,
            'error': 'No face detected'
        }

    if len(face_locations) > 1:
        return {
            'success': False,
            'error': 'Multiple faces detected'
        }

    encodings = face_recognition.face_encodings(
        image,
        face_locations
    )

    if not encodings:
        return {
            'success': False,
            'error': 'Could not generate face encoding'
        }

    return {
        'success': True,
        'encoding': encodings[0].tolist()
    }


if __name__ == '__main__':

    if len(sys.argv) != 2:
        print(json.dumps({
            'success': False,
            'error': 'Image path is required'
        }))
        sys.exit(1)

    image_path = sys.argv[1]

    result = encode_face(image_path)

    print(json.dumps(result))