# Evidence & Confidence Policy

## Claim classes

- VERIFIED
- SUPPORTED
- INFERRED
- UNKNOWN

## Confidence

### HIGH
Critical journeys executed in real runtime.

### MEDIUM
Partial runtime, but major conclusions supported.

### LOW
Static evidence only, target/revision uncertain, or runtime blocked.

Score and confidence are separate.

## Screenshot proves
- layout
- copy
- visible wrapping
- hierarchy
- current visible state

Screenshot does NOT prove
- tap works
- navigation works
- persistence
- animation quality
- keyboard behavior
- performance
- screen reader semantics

## Code proves
- intended logic
- declared labels
- branches/routes

Code does not prove runtime result.

## Re-audit score delta
- 0–2: may be noise/small polish
- 3–4: explain
- >=5: concrete evidence required
- >=10: major material improvement expected

Do not reward implementation effort with score inflation.
