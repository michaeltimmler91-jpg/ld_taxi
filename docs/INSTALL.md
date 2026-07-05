# Installation

## 1. Repository klonen

```bash
git clone https://github.com/michaeltimmler91-jpg/ld_taxi.git
```

## 2. Ressourcen kopieren

Kopiere diese Ordner in deinen FiveM `resources`-Ordner:

```text
resources/ld_taxi
resources/ld_tablet
```

## 3. server.cfg

```cfg
ensure oxmysql
ensure es_extended
ensure ld_taxi
ensure ld_tablet
```

## 4. Neustart

```text
restart ld_taxi
restart ld_tablet
```

## 5. Test

```text
/tablet
/taxitest
```
