# Migration from 2.0.x to 3.0.x

PowerAuth Mobile Flutter SDK version `3.0.0` contains the following breaking changes:

- `PowerAuthPassword` works only with Unicode code points. The string-based character methods were removed.

## Password Code Points

`PowerAuthPassword` stores the password as a sequence of Unicode code points, the same way as the native PowerAuth Mobile SDK. Version `2.x` had methods that accepted a `String`, but they stored only the first code point of the string. A visible character such as `'👍🏽'` or `'e\u0301'` consists of more than one code point, so the rest of the character was lost.

These methods were removed. `addCodePoints()`, `removeCodePointAt()`, and `removeLastCodePoint()` are new in version `3.0.0`.

| Removed method | Replacement |
|---|---|
| `addCharacter(String character)` | `addCodePoints(String text)` or `addCodePoint(int codePoint)` |
| `insertCharacter(String character, int at)` | `insertCodePoint(int codePoint, int at)` |
| `removeCharacterAt(int position)` | `removeCodePointAt(int position)` |
| `removeLastCharacter()` | `removeLastCodePoint()` |

The length and all positions are counted in code points. `removeCodePointAt()` and `removeLastCodePoint()` remove one code point, so they can remove only a part of a visible character. If you implement a custom keyboard, keep its state, such as the cursor position, in code points too.

```dart
// Before
await password.addCharacter(character);
await password.insertCharacter(character, position);
await password.removeLastCharacter();

// After
await password.addCodePoints(character);
var at = position;
for (final codePoint in character.runes) {
    await password.insertCodePoint(codePoint, at++);
}
await password.removeLastCodePoint();
```

`addCodePoints()` adds the code points one by one, so it's not atomic. If it fails, the password may contain only some of them. An empty string adds nothing. `addCharacter('')` and `insertCharacter('', at)` reported `PowerAuthErrorCode.wrongParameter`.

### Existing Passwords

<!-- begin box warning -->
If your app passed a string with more than one code point to `addCharacter()` or `insertCharacter()`, then a password that the user set with version `2.x` contains only the first code point of each such string. When you add every code point with version `3.0.0`, the password doesn't match. Authentication then fails, and every attempt counts toward the activation's maximum failure count, which can block the activation.
<!-- end -->

Passwords that use only single code point characters, such as numeric PINs, are not affected. To keep accepting passwords that were set with version `2.x`, add only the first code point of each non-empty character:

```dart
await password.addCodePoint(character.runes.first);
await password.insertCodePoint(character.runes.first, position);
```

Use the same scheme every time the user enters a password, including when they set a new one. To switch such a user to full code points, change the password: pass the old password with only the first code points to `beginPasswordChange()` and the new password with all code points to `finishPasswordChange()`.

`PowerAuthPassword.fromString()` already added every code point in version `2.x`, so passwords created with it are not affected.

## Read Next

- [Working with passwords securely](Secure-Password.md)
- [Migration Instructions](Migration-Instructions.md)
