# Quality Gate

Antes de cada commit, ejecutar:

```bash
flutter analyze   # 0 issues — bloqueante
flutter test      # 0 failures — bloqueante
```

El pre-commit hook en `.git/hooks/pre-commit` ejecuta ambos automáticamente. Si fallan, el commit se rechaza.

Commit message: Conventional Commits (`feat`, `fix`, `refactor`, `test`, `docs`, `chore`).
