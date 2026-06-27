class CourseAccessService {
  bool canWatchLesson({
    required bool isFree,
    required bool hasCourseEnrollment,
    required bool hasBundleEnrollment,
  }) {
    // Free course → everything open
    if (isFree) return true;

    // Paid course → must have access
    if (hasCourseEnrollment || hasBundleEnrollment) {
      return true;
    }

    return false;
  }
}