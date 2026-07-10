# MASTER DEVELOPMENT INSTRUCTIONS

## 1. PROJECT EXECUTION RULES (HIGHEST PRIORITY)

These instructions are mandatory throughout the entire development process.

Failure to follow them is considered a task failure.

---

## 2. Planning Before Coding

Before writing any code:

* Read every document inside **PRODUCT SPECIFICATION DOCS**.
* Read **DESIGN-SYSTEM.md** completely.
* Study every image inside the **references/** folder.
* Understand the entire product before implementation.
* Create an implementation plan mentally before starting development.
* Never jump directly into coding.

The UI reference images are **design inspiration only**.

Do **not** copy them pixel-for-pixel.

Follow their design language while producing an original implementation.

You may freely modify **DESIGN-SYSTEM.md** to improve consistency by updating design tokens, colors, typography, spacing, or reusable design guidelines.

---

## 3. Git Workflow (MANDATORY)

Version control is required from the very beginning.

Before writing any application code:

- Initialize Git.
- Initialize the Flutter project if necessary.

During development:

- Commit frequently.
- Keep commits small and focused.
- Every commit must represent one complete logical change.
- Every commit must be independently understandable and reviewable.
- Commit only completed, working changes.
- Never batch multiple unrelated changes into a single commit.
- If a feature is large, split it into multiple logical commits.
- Never wait until the project is complete before committing.

A commit should typically represent one of the following:

- One reusable UI component
- One complete screen
- One navigation flow
- One feature implementation
- One bug fix
- One refactoring
- One documentation update

A commit is too small if it represents only part of a logical change.

A commit is too large if it combines multiple unrelated features or would be difficult for a reviewer to understand quickly.

When making commits:

- Use ONLY the Git account already configured on this machine.
- Never commit using Claude's account.
- You may optionally add Claude as a co-author.
- The primary author must always be the user's configured Git account.

The repository remote will **NOT** exist initially.

The repository URL will be provided after development is complete.

Do **not** ask for it before then.

When provided:

- Add the remote as `origin`.
- Do not rewrite Git history.
- Do not squash or rebase existing commits unless explicitly instructed.
- Allow the user to perform the final push manually or push when the user specifies to do so.

## 4. Flutter Requirements

Implement the application as a complete production-ready Flutter application.

Requirements:

* No placeholder application.
* No incomplete flows.
* No fake navigation.
* No unfinished screens.

The application must be usable from first launch until normal daily usage.

---

## 5. Emulator Policy

Do **not** launch an Android emulator.

When development is complete:

* Build an APK.
* The user will perform manual testing.

Later, when requested:

* build the release AAB.

---

## 6. App Size

Keep both download size and installed size as small as reasonably possible.

Avoid unnecessary dependencies.

Avoid packages that significantly increase binary size unless absolutely necessary.

Examples include:

* unnecessary font packages
* large asset libraries
* redundant plugins

---

## 7. Data Policy

Do not populate the application with dummy user data.

A new installation should begin empty.

Instructional onboarding content is acceptable.

Fake user records are not.

---

## 8. Navigation Rules

Navigation must always feel natural.

Requirements:

* No dead-end routes.
* No blank screens.
* No broken navigation.
* No inaccessible screens.

The Home screen is the navigation root.

Behavior:

* Back from normal screens returns to the previous screen.
* Back from Home exits the application.
* Never allow navigation to Flutter's default empty "/" route.
* Never allow a back button on Home that navigates to an empty route.

---

## 9. UI & UX Quality

The application must be visually robust across different devices.

Prevent:

* text clipping
* overflowing widgets
* distorted layouts
* overlapping controls
* inconsistent spacing
* inaccessible controls

Maintain:

* responsive layouts
* proper padding
* safe area support
* readable typography
* consistent spacing

The application should remain usable across different screen sizes and aspect ratios.

---

## 10. User Experience

Every feature should provide a polished experience.

Do not leave:

* disabled buttons
* unfinished interactions
* confusing flows
* broken dialogs
* inconsistent behavior

Every visible action should perform its intended function.

---

## 11. Settings

Include meaningful user settings where appropriate.

Do not add settings merely to increase feature count.

Every setting should solve a real user need.

---

## 12. Product Decisions

If the specification is missing minor implementation details:

* infer sensible defaults
* follow platform conventions
* continue development without unnecessary questions

Only request clarification when blocked by a major product decision.

---

## 13. Privacy & Compliance

The application must be designed with Google Play policies in mind.

Avoid requesting unnecessary permissions.

Avoid collecting unnecessary user information.

Avoid features likely to violate Play Store policies.

Prepare:

* Privacy Policy
* Terms & Conditions

Requirements:

* Do not include personal contact information.
* Use plain language understandable by non-technical users.
* Mention Firebase Analytics in a general, user-friendly manner.
* Assume Firebase Analytics will be integrated later.

---

## 14. Firebase

Firebase configuration will be supplied later.

Until then:

* prepare integration points
* avoid hardcoded project values
* write the privacy policy assuming Firebase Analytics will eventually be enabled

Do not ask for Firebase configuration during development.

---

## 15. Package Name

Do not ask for the Android package name.

It will be provided only after:

* development
* testing
* release preparation

The package name should be easy to replace from one location.

---

## 16. App Name

The final app name will also be provided later.

Design the project so the application name can be changed from one central configuration.

Avoid hardcoding the name throughout the project.

---

## 17. Documentation

When development is complete, create:

### README.md

The README should:

* explain the application
* describe all features
* explain how the app is used
* avoid unnecessary technical implementation details

Write it for end users rather than developers.

---

### CHANGELOG.md

Initial version:

**1.0.0**

Include:

* release overview
* complete feature list
* notable functionality

Future versions:

Append new entries.
Modify the version specified inside the app.

Never overwrite previous release notes.

Only increment the version when explicitly instructed.

---

## 18. Final Build Deliverables

When development is complete:

* ensure the project builds successfully
* generate the APK
* verify all navigation
* verify all buttons
* verify responsive layouts
* verify no obvious UI issues
* verify no runtime crashes
* verify documentation is complete

Only after successful verification should the project be considered finished.

---

## 19. General Development Philosophy

Throughout development:

* Prefer maintainability over shortcuts.
* Prefer reusable architecture over duplication.
* Keep code clean, modular, and readable.
* Minimize unnecessary dependencies.
* Follow Flutter best practices.
* Prioritize reliability, consistency, and user experience over rapid implementation.

## 20. Architecture

The project must follow a clean, scalable architecture.

Requirements:

- Separate UI, business logic, and data layers.
- Avoid putting business logic inside widgets.
- Keep widgets small and reusable.
- Prefer composition over large monolithic screens.
- Reuse components whenever practical.
- Use dependency injection where appropriate.
- Avoid global mutable state unless absolutely necessary.

## 21. Code Quality

The codebase should remain production quality throughout development.

Requirements:

- No commented-out code.
- No dead code.
- No unused assets.
- No unused dependencies.
- No TODOs left unresolved.
- Avoid duplicated logic.
- Prefer readable code over clever code.
- Follow effective Dart and Flutter style guidelines.

## 22. Performance

The application should remain smooth even on low-end Android devices.

Requirements:

- Avoid unnecessary widget rebuilds.
- Dispose controllers correctly.
- Minimize memory usage.
- Avoid blocking the UI thread.
- Use lazy loading where appropriate.
- Optimize images and assets.

## 23. Error Handling

The application must fail gracefully.

Requirements:

- Never crash because of user actions.
- Handle invalid input.
- Handle missing data.
- Handle network failures.
- Show user-friendly error messages.
- Avoid exposing stack traces to users.

## 24. Security

Follow secure development practices.

Requirements:

- Never hardcode secrets.
- Never hardcode API keys.
- Never commit sensitive credentials.
- Validate all user input.
- Store sensitive information securely.
- Prepare the app for future secure backend integration, only if required.

## 25. Before Every Commit

Before creating each Git commit, verify that:

- No analyzer errors exist.
- No obvious UI regressions were introduced.
- No unrelated files were modified.
- The commit contains one logical change only.

# Final Verification

Before declaring the project complete, verify:

✓ Every feature from the specification has been implemented.
✓ Every screen is reachable.
✓ Every button performs its intended action.
✓ No placeholder UI remains.
✓ No dummy data remains.
✓ Navigation works correctly.
✓ The project builds successfully.
✓ APK has been generated.
✓ README is complete.
✓ CHANGELOG is complete.
✓ Privacy Policy is included.
✓ Terms & Conditions are included.
✓ Git history contains small, logical commits.

Only after all items are verified should the project be considered complete.