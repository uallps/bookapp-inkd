#!/bin/bash
# Prueba de interfaz en Linux: pantalla virtual (Xvfb), clics con xdotool y capturas en shots/.
# Sin gestor de ventanas, la ventana (800x600) queda en la esquina superior izquierda.
#   linux-ui.sh               producto base
#   linux-ui.sh Notas,Prestamos,FechasLectura   producto con esos traits
set -u
VARIANT=${1:-base}
OUT=shots/${VARIANT//,/+}
mkdir -p "$OUT"
export DISPLAY=:99 GDK_BACKEND=x11 GSK_RENDERER=cairo LANG=C.UTF-8 LC_ALL=C.UTF-8
pgrep -x Xvfb >/dev/null || { Xvfb :99 -screen 0 1280x800x24 2>/dev/null & sleep 2; }

TRAITS=()
[ "$VARIANT" != base ] && TRAITS=(--traits "$VARIANT")
swift build --product inkd "${TRAITS[@]}" || exit 1
BIN="$(swift build --product inkd "${TRAITS[@]}" --show-bin-path)/inkd"

# Empezar sin datos guardados: libros (JSON) y ajustes (UserDefaults).
rm -f ~/Documents/books.json ~/.config/inkd.plist

start() { "$BIN" > "$OUT/app.log" 2>&1 & APP=$!; sleep 5; }
shot()  { import -window root "$OUT/$1.png"; echo "captura: $OUT/$1.png"; }
click() { xdotool mousemove "$1" "$2" click 1; sleep 1; }
alive() { kill -0 $APP 2>/dev/null || { echo "La app se ha cerrado"; cat "$OUT/app.log"; exit 1; }; }

# Barra lateral (Biblioteca / Ajustes) a la izquierda; el contenido, a la derecha.
# Solo se pulsa la barra lateral: las filas de la biblioteca dependen del formulario de alta
# y sus coordenadas aún no se han medido en Linux.
start; alive; shot 1-inicio
click 77 106;       shot 2-ajustes                      # Ajustes
click 77 74;        shot 3-biblioteca                   # Biblioteca
alive
kill $APP; sleep 1

# Al volver a abrir, la app arranca con los datos guardados.
start; alive; shot 4-tras-reiniciar
kill $APP
