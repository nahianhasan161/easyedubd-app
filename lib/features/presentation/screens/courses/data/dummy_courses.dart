import 'package:easyedubd_app/features/presentation/screens/courses/models/course.dart';
import 'package:easyedubd_app/features/presentation/screens/courses/models/chapter.dart';

import 'package:easyedubd_app/features/presentation/screens/courses/models/lessons.dart';

final List<Course> dummyCourses = [
  Course(
    id: '1',
    title: 'Physical Chemistry | Honours 1st year',
    description:
        'ভৌত রসায়ন কোর্সঃ রসায়ন-১ কোর্স কোডঃ ২১২৮০১ সেশনঃ ২০২৫-২৬ যেকোনো একটি ডিভাইস থেকে লগইন করতে পারবেন । Easy Education BD -তে যেকোনো কোর্স বুকিং বা পেমেন্ট ফেরতযোগ্য নয় ',
    imageUrl:
        'https://easyedubd-lms.t3.tigrisfiles.io/61c559da-ad79-4c04-986c-c800b6e52949-Teal%20Green%20White%20Abstract%20Chemistry%20Project%20Obervation%20Presentation.png',
    progress: 0.3,
    chapters: [
      Chapter(
        id: 'c2',
        title: 'দ্বিতীয় অধ্যায়ঃ(অনুর ধর্মসমূহ)',
        description: 'Click to see the lectures',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lecture 1',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'NrLLeV_VqhM',
          ),
          Lesson(
            id: 'l2',
            title: 'Lecture 2',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'Q43fEcRBCOE',
          ),
          Lesson(
            id: 'l3',
            title: 'Lecture 3',
            description: 'Video Class',
            videoUrl: 'https://youtu.be/hnX9ArE-S6k',
            duration: const Duration(minutes: 5),
            videoId: 'hnX9ArE-S6k',
          ),
          Lesson(
            id: 'l4',
            title: 'Lecture 4',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: '-RnoG_P4LbY',
          ),
        ],
      ),
      Chapter(
        id: 'c3',
        title: 'তৃতীয় অধ্যায়ঃ(গ্যাসীয় অবস্থা)',
        description: 'Click to see the lectures',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lecture 1',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'OwwYolpyKcE',
          ),
          Lesson(
            id: 'l2',
            title: 'Lecture 2',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'hAqjypkTcgo',
          ),
          Lesson(
            id: 'l3',
            title: 'Lecture 3',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: '4jL1LxZkSVE',
          ),
          Lesson(
            id: 'l4',
            title: 'Lecture 4',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'qXcPuPhuo30',
          ),
          Lesson(
            id: 'l5',
            title: 'Lecture 5',
            description: 'Video Class',
            videoUrl: 'https://youtu.be/C-adOpOpVLs',
            duration: const Duration(minutes: 5),
            videoId: 'C-adOpOpVLs',
          ),
          Lesson(
            id: 'l6',
            title: 'Lecture 6',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'mOYTCs0BiVg',
          ),
          Lesson(
            id: 'l7',
            title: 'Lecture 7',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'B4eRnJLKyZ4',
          ),
        ],
      ),
      Chapter(
        id: 'c4',
        title: 'চতুর্থ অধ্যায়ঃ(তরল ও দ্রবণ)',
        description: 'Click to see the lectures',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lecture 1',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: '1lae-4dX0LU',
          ),
          Lesson(
            id: 'l2',
            title: 'Lecture 2',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'fEqbMugEPQM',
          ),
          Lesson(
            id: 'l3',
            title: 'Lecture 3',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'OKDTKExrmcI',
          ),
          Lesson(
            id: 'l4',
            title: 'Lecture 4',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'C9FyLBltA1o',
          ),
          Lesson(
            id: 'l5',
            title: 'Lecture 5',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'AnabAi9Olug',
          ),
          Lesson(
            id: 'l6',
            title: 'Lecture 6',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'e4DPGpDnXOg',
          ),
          Lesson(
            id: 'l7',
            title: 'Lecture 7',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'ChETjXV33bA',
          ),
        ],
      ),
      Chapter(
        id: 'c5',
        title: 'পঞ্চম অধ্যায়ঃ(রাসায়নিক সাম্যাবস্থা)',
        description: 'Click to see the lectures',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lecture 1',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'GrpA0x6xnQQ',
          ),
          Lesson(
            id: 'l2',
            title: 'Lecture 2',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'nQ2if2peOTk',
          ),
        ],
      ),
      Chapter(
        id: 'c6',
        title: 'ষষ্ঠ অধ্যায়ঃ(PH এবং বাফার)',
        description: 'Click to see the lectures',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lecture 1',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'RHgr0ZqSPKU',
          ),
          Lesson(
            id: 'l2',
            title: 'Lecture 2',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'NJpL9qIxklU',
          ),
          Lesson(
            id: 'l3',
            title: 'Lecture 3',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'rG5p4Rj40Zk',
          ),
          Lesson(
            id: 'l4',
            title: 'Lecture 4',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'aWsz68QA3s4',
          ),
        ],
      ),
      Chapter(
        id: 'c7',
        title: '৭ম অধ্যায়ঃ(রাসায়নিক শক্তি বিজ্ঞান)',
        description: 'Click to see the lectures',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lecture 1',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: '9jsnGGKDtXA',
          ),
          Lesson(
            id: 'l2',
            title: 'Lecture 2',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'RaclHe0eJtM',
          ),
          Lesson(
            id: 'l3',
            title: 'Lecture 3',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'uMKMQ6rLS5w',
          ),
          Lesson(
            id: 'l4',
            title: 'Lecture 4',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'rngZcxPARk8',
          ),
          Lesson(
            id: 'l5',
            title: 'Lecture 5',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'y0jGUDhM5Mo',
          ),
          Lesson(
            id: 'l6',
            title: 'Lecture 6',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'szlp5jk_QCY',
          ),
          Lesson(
            id: 'l7',
            title: 'Lecture 7',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'UM7a0XMZYn8',
          ),
          Lesson(
            id: 'l8',
            title: 'Lecture 8',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'JgTTKNcjiyg',
          ),
          Lesson(
            id: 'l9',
            title: 'Lecture 9',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'Z2ybeqp7QEk',
          ),
          Lesson(
            id: 'l10',
            title: 'Lecture 10',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'ZanVF3Ug_4o',
          ),
        ],
      ),
      Chapter(
        id: 'c8',
        title: '৮ম অধ্যায়ঃ(তাপ রসায়ন)',
        description: 'Click to see the lectures',
        lessons: [
          Lesson(
            id: 'l1',
            title: 'Lecture 1',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'oQ1-JyI4kp8',
          ),
          Lesson(
            id: 'l2',
            title: 'Lecture 2',
            description: 'Video Class',

            duration: const Duration(minutes: 5),
            videoId: 'LDyUFb7jHKo',
          ),
        ],
      ),
    ],
  ),
];
