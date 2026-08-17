# vendor_samsung_a35x

Vendor tree (blobs propietarios) para el **Samsung Galaxy A35 5G**
(codename `a35x`, modelo `SM-A356E`, plataforma `erd8835` / Exynos 1380).

Complementa a [`shrp_device_samsung_a35x`](https://github.com/christiandroid20/shrp_device_samsung_a35x)
(y a futuro, al device tree de ROMs). No existía públicamente para este
equipo antes de este repo.

## Uso

Clonar en `vendor/samsung/a35x` dentro del árbol de compilación, junto
al device tree en `device/samsung/a35x`.

### Extraer los blobs

Con el equipo conectado por ADB (necesita acceso root):

```
./extract-files.sh
```

O desde un dump de firmware ya extraído (AP+CSC+BL+CP):

```
./extract-files.sh /ruta/al/dump
```

Esto llena `proprietary/` con los archivos reales y regenera
`Android.mk` / `a35x-vendor.mk` automáticamente (via `setup-makefiles.sh`).

## Estado actual

`proprietary-files.txt` trae ya anotadas, por categoría, las piezas que
sabemos que existen en este equipo (confirmado durante el trabajo del
[recovery custom](https://github.com/christiandroid20/shrp_device_samsung_a35x)):
TEE/Keymint/Gatekeeper, paneles, sensores de cámara, haptics y carga.
Faltan las rutas completas reales y el resto del árbol -- se completa
corriendo `extract-files.sh` contra el equipo o un firmware oficial
completo del modelo MXO.
