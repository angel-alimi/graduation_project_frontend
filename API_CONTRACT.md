# LifeShare REST API — contract for the Spring Boot backend

The Flutter app (`lib/data/remote_api.dart`) calls exactly these endpoints.
Build the backend to match, then run the app with `--dart-define=USE_MOCK=false`.

## General rules

| Item | Value |
|---|---|
| Base URL | `http://<host>:8080` (set with `--dart-define=API_URL=...`) |
| Format | JSON, UTF-8, field names in **camelCase** |
| Auth | `Authorization: Bearer <JWT>` on every endpoint except `/api/cities`, `/api/hospitals` and `/api/auth/**` |
| Language | The app sends `Accept-Language: ar` or `en`. Use it for error messages. |
| Dates | `birthDate`, `lastDonationDate` → `"YYYY-MM-DD"` (Java `LocalDate`) |
| Timestamps | `createdAt`, `neededAt` → ISO-8601 with offset, e.g. `"2026-11-04T16:20:00+02:00"` (Java `OffsetDateTime`) |
| Phone | Always 9 local digits without +970 or leading 0, e.g. `"591234567"` |
| Errors | Any non-2xx status with a body `{ "message": "..." }`. The app shows `message` to the user. Use status **401** when the token is missing or expired (the app then logs the user out). For a wrong OTP, return **400** with `{ "message": "invalid_code" }` and the app shows its own translated text. |

### Enums (use these exact names in Java)

```java
enum BloodType       { A_POS, A_NEG, B_POS, B_NEG, AB_POS, AB_NEG, O_POS, O_NEG }
enum Gender          { FEMALE, MALE }
enum Urgency         { NORMAL, URGENT }
enum RequestStatus   { OPEN, FULFILLED, CANCELLED }
enum ResponseStatus  { ACCEPTED, DECLINED, INELIGIBLE, CANCELLED, COMPLETED }
enum OtpPurpose      { SIGNUP, LOGIN }
enum NotificationType{ MATCH, REQUEST_POSTED, REMINDER, WELCOME }
```

### JSON objects

**City**
```json
{ "id": 1, "nameAr": "رام الله", "nameEn": "Ramallah" }
```
Seed the `cities` and `hospitals` tables from `lib/data/palestine_data.dart`, keeping the same ids.

**Hospital**
```json
{ "id": 1, "nameAr": "مجمع فلسطين الطبي", "nameEn": "Palestine Medical Complex", "cityId": 1 }
```

**User** (the signed-in user)
```json
{
  "id": 7,
  "fullName": "أمل نبيه",
  "phone": "591234567",
  "gender": "FEMALE",
  "birthDate": "2002-07-05",
  "cityId": 1,
  "bloodType": "B_POS",
  "lastDonationDate": null,
  "requestsCount": 0,
  "responsesCount": 0
}
```
`requestsCount` = the user's requests that are not cancelled. `responsesCount` = the user's responses with status ACCEPTED or COMPLETED. Both are computed (no columns needed).

**BloodRequest**
```json
{
  "id": 12,
  "requesterName": "سارة ك.",
  "hospitalId": 1,
  "cityId": 1,
  "bloodType": "B_POS",
  "unitsNeeded": 2,
  "urgency": "URGENT",
  "patientName": "مريم خليل",
  "note": "قبل عملية غداً صباحاً.",
  "neededAt": "2026-11-05T07:00:00Z",
  "status": "OPEN",
  "createdAt": "2026-11-04T16:20:00+02:00",
  "mine": false,
  "myResponse": null
}
```
- `cityId` = the hospital's city (join, not stored on the request).
- `requesterName` = the requester's name. You can shorten it for privacy (e.g. "سارة ك.").
- `mine` = true when the signed-in user created the request.
- `myResponse` = the signed-in user's response status for this request, or `null`.

**EligibilityQuestion**
```json
{ "id": 1, "textAr": "هل تبرعت بالدم خلال آخر 56 يوماً؟", "textEn": "Have you donated blood in the last 56 days?", "disqualifyingAnswer": true }
```

**Notification**
```json
{
  "id": 30,
  "type": "MATCH",
  "requestId": 12,
  "bloodType": "B_POS",
  "hospitalId": 1,
  "personName": "سارة ك.",
  "createdAt": "2026-11-04T16:20:00+02:00",
  "read": false
}
```
The app writes the notification text itself from `type` and the fields, so you don't store translated text. Fields not needed by a type can be `null`.

---

## Endpoints

### Lookups (no token)

| Method | Path | Response |
|---|---|---|
| GET | `/api/cities` | `City[]` |
| GET | `/api/hospitals` | `Hospital[]` (all of them; the app filters by city) |

### Auth (no token)

**1. Send a code** — `POST /api/auth/otp`
```json
{ "phone": "591234567", "purpose": "SIGNUP" }
```
→ `204 No Content` (or `200 {}`).
- `SIGNUP` with a phone that already has an account → `409 { "message": "This number already has an account. Log in instead." }`
- `LOGIN` with a phone that has no account → `404 { "message": "No account for this number. Create one first." }`
- Send the code by SMS; store only a hash of it with an expiry (e.g. 5 minutes) and an attempt limit.

**2. Create the account** — `POST /api/auth/signup`
```json
{
  "phone": "591234567",
  "code": "482913",
  "fullName": "أمل نبيه",
  "gender": "FEMALE",
  "birthDate": "2002-07-05",
  "cityId": 1,
  "bloodType": "B_POS",
  "lastDonationDate": "2026-10-01"
}
```
→ `200 { "token": "<JWT>", "user": User }`
`lastDonationDate` is optional; `null` means the user has never donated.
Validate: age ≥ 17, name ≥ 3 characters, city exists, code valid, `lastDonationDate` not in the future and not before `birthDate`.

**3. Log in** — `POST /api/auth/login`
```json
{ "phone": "591234567", "code": "482913" }
```
→ `200 { "token": "<JWT>", "user": User }`

### Current user (token)

| Method | Path | Body | Response |
|---|---|---|---|
| GET | `/api/users/me` | – | `User` |
| PATCH | `/api/users/me` | `{ "lastDonationDate": "2026-10-01" }` | `User` |

Later you can also accept `{ "fcmToken": "..." }` on the same PATCH for push notifications.

### Blood requests (token)

| Method | Path | Notes | Response |
|---|---|---|---|
| GET | `/api/requests?urgency=URGENT&q=رام` | Public feed. Only `OPEN` requests, newest first. Both query params are optional. `q` searches requester name, note, hospital and city names. | `BloodRequest[]` |
| GET | `/api/requests/mine` | The user's requests, not cancelled, newest first. | `BloodRequest[]` |
| GET | `/api/requests/matched` | `OPEN` requests from **other** users whose blood type the user **can donate to** (see table below). Same city first is a good default. | `BloodRequest[]` |
| POST | `/api/requests` | Body below. The requester is the signed-in user. | `BloodRequest` (201) |
| PATCH | `/api/requests/{id}/cancel` | Only the owner. Sets status `CANCELLED`. | `204` |

`POST /api/requests` body:
```json
{
  "patientName": "مريم خليل",
  "bloodType": "B_POS",
  "unitsNeeded": 2,
  "hospitalId": 1,
  "urgency": "URGENT",
  "neededAt": "2026-11-05T07:00:00Z",
  "note": "قبل عملية غداً صباحاً."
}
```
`patientName` and `note` can be `null`. `unitsNeeded` is 1–10. `neededAt` is required, sent in UTC, and must be in the future.
Store and return `patientName` and `note` exactly as written. Never translate them.

### Responding to a request (token)

| Method | Path | Response |
|---|---|---|
| GET | `/api/eligibility-questions` | `EligibilityQuestion[]` |
| POST | `/api/requests/{id}/responses` | `{ "status": "ACCEPTED" }` or `{ "status": "INELIGIBLE" }` |

Body:
```json
{ "answers": [ { "questionId": 1, "answer": false }, { "questionId": 2, "answer": false }, { "questionId": 3, "answer": false } ] }
```
The backend decides the status:
- any answer equal to the question's `disqualifyingAnswer` → `INELIGIBLE`
- the user's `lastDonationDate` is less than 56 days ago → `INELIGIBLE`
- otherwise → `ACCEPTED`, and notify the requester.

Return `409` if the user already responded, or if the request is the user's own or not `OPEN`.

### Notifications (token)

| Method | Path | Response |
|---|---|---|
| GET | `/api/notifications` | `Notification[]`, newest first |
| POST | `/api/notifications/read-all` | `204` |

---

## Blood compatibility used by `/api/requests/matched`

| Donor | Can donate to |
|---|---|
| O− | everyone |
| O+ | O+, A+, B+, AB+ |
| A− | A−, A+, AB−, AB+ |
| A+ | A+, AB+ |
| B− | B−, B+, AB−, AB+ |
| B+ | B+, AB+ |
| AB− | AB−, AB+ |
| AB+ | AB+ |

The same table is in the app: `lib/models/enums.dart` → `BloodType.canDonateTo`.

## Spring Boot checklist

- `spring-boot-starter-web`, `-data-jpa`, `-validation`, `-security`, PostgreSQL driver, a JWT library (e.g. `io.jsonwebtoken:jjwt`).
- Jackson: dates as strings, not timestamps — `spring.jackson.serialization.write-dates-as-timestamps=false`.
- Enums map to the names above (`@Enumerated(EnumType.STRING)` in entities).
- Security: permit `/api/auth/**`, `/api/cities`, `/api/hospitals`; everything else authenticated with a JWT filter. Return 401 (not a redirect) when the token is missing.
- If you also run the app in Chrome (`flutter run -d chrome`), allow CORS for `http://localhost:*`.
- A `@RestControllerAdvice` that turns exceptions into `{ "message": "..." }` keeps the app's error messages readable.
