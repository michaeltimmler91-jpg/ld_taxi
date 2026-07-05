# LD Taxi

FiveM/ESX Taxi-System mit eigenem Tablet-Framework.

## Ressourcen

```text
resources/ld_taxi     Taxi-Backend, Datenbank, Events, Logik
resources/ld_tablet   Tablet-UI, Prop, Animation, NUI
```

## Startreihenfolge

```cfg
ensure oxmysql
ensure es_extended
ensure ld_taxi
ensure ld_tablet
```

## Testbefehle

```text
/tablet
/tabletreset
/taxitest
/taxidienst
/taxioff
/leitstelle
/leitstelleoff
```
