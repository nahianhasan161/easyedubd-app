# Project Overview

## Overview
Easy Education Bangladesh (`com.easyeducationbd.app`) is a course app for students. Courses contain
chapters, which contain lessons (YouTube videos). Courses can be free or paid. A paid course is unlocked by an enrollment
(per course or via a bundle) that an admin creates. Each account is locked to approved devices,
and screenshots/screen recording are blocked.

## Goals
- Deliver video lessons only to enrolled students on approved devices (content protection).
- Let admins manage courses, enrollments, promotions, users, and devices from inside the app (no separate web admin).
- Work on slow or flaky connections: offline browsing from the Hive cache, timeouts everywhere.
- TBD (ask): business goals (number of students, revenue model, payment flow: enrollment is manual today).

## Core User Flows

### Student
1. Opens the app → `/splash` → `StartupController` checks the session, device, and profile.
2. Not signed in → `/` login (email/password or Google).
3. First launch on a device → `verify_device` RPC → `/device-pending` until an admin approves (or `/device-blocked`).
4. Missing profile fields → `/profile-onboarding` (name, phone, level, institute, gender…). There's also an intro `/onboarding`.
5. `/dashboard` (tabs): course sliders and recommendations, then `/courses` (search, filter by year/subject/type).
6. `/course/:courseId` → chapters/lessons. Locked unless free or enrolled (`CourseAccessService`).
7. `/lesson/:videoId` → YouTube player, then "Mark as complete" writes `lesson_progress`.
8. Profile, notifications, contact screens from the dashboard.

### Admin (`profiles.role = 'admin'`)
1. Opens the admin drawer on the dashboard (`dashboard/admin_drawer.dart`).
2. Users: `/admin/users` → search (RPC `search_profiles`) → detail → devices (approve or revoke).
3. Enrollments: `/admin/courses` → pick a course → `/admin/courses/:id/enrollments` → add or remove a student.
4. Content: `/admin/course-management` → chapters → lessons (CRUD).
5. Promotions: `/admin/promotions` → assign courses (`promotion_course`).

## Features
- **Auth & access**: Supabase email + Google sign-in, device approval, profile-completion gate, admin route guard.
- **Content**: courses, chapters, lessons, bundles, promotions/discounts, search, pagination, recommendations.
- **Learning**: YouTube lesson player, per-user lesson progress, "coming soon" lessons.
- **Offline/cache**: Hive cache, server `cache_version` invalidation on resume, tab change, and pull-to-refresh.
- **Security**: screenshot block (`ScreenSecurityService`), device fingerprint, `security_test_screen.dart`.
- **Analytics**: PostHog events, session replay (text masked), error tracking.

## Scope
**In:** Android (Play Store), Windows build, the student flows and in-app admin above.
**Out for now / placeholders:** exams (`screens/exam/` is empty), live streams (`screens/live_stream/` is empty),
in-app payments. TBD (ask): iOS/web release plans.

## Success Criteria
- TBD (ask). Technical baseline: `flutter analyze` is clean, `flutter test` passes, a student sees fresh data after an admin
  edit (on resume or pull-to-refresh) without reinstalling, and progress is never shared between users.
