# Prueba de interfaz en Windows del producto completo (traits Notas, Prestamos y FechasLectura):
# arranca la app, prueba las tres características y guarda capturas y controles en shots/.
# Igual que windows-ui.ps1: los textos son controles Static; los botones de texto los dibuja
# SwiftOpenUI con Direct2D (SwiftUID2DSurface, sin texto), así que se buscan por posición.
. "$PSScriptRoot/ui.ps1"
$traits = "Notas,Prestamos,FechasLectura"
swift build --product inkd --traits $traits | Out-Null
$bin = swift build --product inkd --traits $traits --show-bin-path

# Empezar sin libros guardados (¡en local borra tu biblioteca de Documentos!) ni ajustes
# (UserDefaults en Windows: %LOCALAPPDATA%\inkd.exe.plist).
Remove-Item (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "books.json") -ErrorAction SilentlyContinue
Remove-Item (Join-Path $env:LOCALAPPDATA "inkd.exe.plist") -ErrorAction SilentlyContinue

function Count-Text([string]$text) { @(Get-Controls $w | Where-Object { $_.Text -eq $text }).Count }
function Count-Like([string]$pattern) { @(Get-Controls $w | Where-Object { $_.Text -like $pattern }).Count }
function Count-Class([string]$class) { @(Get-Controls $w | Where-Object { $_.Class -eq $class }).Count }

# Clic en el botón de marcar de una fila: el botón pequeño (24 px) a la izquierda del título.
function Click-Toggle([string]$title) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $title } | Select-Object -First 1
    if (-not $c) { throw "No hay una fila '$title'" }
    $b = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUICustomButton" -and $_.W -le 32 -and $_.X -lt $c.X } |
        Sort-Object { [math]::Abs(($_.Y + $_.H / 2) - ($c.Y + $c.H / 2)) } | Select-Object -First 1
    if (-not $b) { throw "No hay botón de marcar junto a '$title'" }
    Click-At ($b.X + [int]($b.W / 2)) ($b.Y + [int]($b.H / 2))
}

# Clic en una opción de la barra lateral: el texto más a la izquierda con ese nombre.
function Click-Sidebar([string]$text) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $text -or $_.Text -like "* $text" } |
        Sort-Object X | Select-Object -First 1
    if (-not $c) { return $false }
    Click-At ($c.X + [int]($c.W / 2)) ($c.Y + [int]($c.H / 2))
    return $true
}

# El campo de texto número $n (desde 1) del detalle, de arriba abajo.
function Get-Edit([int]$n) {
    $edits = @(Get-Controls $w | Where-Object { $_.Class -eq "Edit" } | Sort-Object Y)
    if ($edits.Count -lt $n) { throw "No hay campo de texto número $n" }
    return $edits[$n - 1]
}

function Click-Control($c) { Click-At ($c.X + [int]($c.W / 2)) ($c.Y + [int]($c.H / 2)) }

# Clic en el primer botón de texto (SwiftUID2DSurface) que hay debajo del control $c.
function Click-ButtonBelow($c) {
    $b = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUID2DSurface" -and $_.Y -ge ($c.Y + $c.H) } |
        Sort-Object Y | Select-Object -First 1
    if (-not $b) { throw "No hay botón debajo de '$($c.Text)'" }
    Click-Control $b
}

$app = Start-App "$bin\inkd.exe" "completo"
if ($app.HasExited) { throw "La app se ha cerrado al arrancar" }
$w = Get-AppWindow $app.Id
Snap $w "completo-1-inicio"
if ((Count-Text "Prestado a Lucía") -ne 1) { throw "No se ve el préstamo de ejemplo" }
if ((Count-Text "1 cita") -ne 1) { throw "No se ve el resumen de notas de ejemplo" }
if ((Count-Like "Leído el *") -ne 1) { throw "No se ve la fecha de fin de ejemplo" }
if ((Count-Like "Empezado el *") -ne 1) { throw "No se ve la fecha de inicio de ejemplo" }

# O2: pasar El principito a Leyendo apunta la fecha de inicio.
Click-Toggle "El principito"; Snap $w "completo-2-leyendo"
if ((Count-Like "Empezado el *") -ne 2) { throw "Al pasar a Leyendo no se ha apuntado la fecha de inicio" }

# Detalle con las tres secciones.
if (-not (Click-Text $w "El principito")) { throw "No está la fila El principito" }
Snap $w "completo-3-detalle"
foreach ($t in "Fechas de lectura", "Préstamo", "Notas y citas") {
    if ((Count-Text $t) -ne 1) { throw "El detalle no muestra la sección $t" }
}
if ((Count-Class "SysDateTimePick32") -ne 2) { throw "Deberían verse las fechas de inicio y de préstamo" }

# O1: devolver el libro y prestárselo a otra persona.
$prestado = Get-Controls $w | Where-Object { $_.Text -eq "Prestado a Lucía" } | Select-Object -First 1
Click-ButtonBelow $prestado; Snap $w "completo-4-devuelto"               # «Marcar como devuelto»
if ((Count-Text "En casa") -ne 1) { throw "El libro debería estar en casa" }
$campo = Get-Edit 3                                                       # «Prestar a»
Click-Control $campo; Send-Text "Ana"
Click-ButtonBelow $campo; Snap $w "completo-5-prestado"                  # «Prestar»
if ((Count-Text "Prestado a Ana") -ne 1) { throw "No se ha prestado el libro a Ana" }

# F2: añadir una nota (tras prestar, el 3.º campo es «Nueva nota o cita» y el 4.º la página).
Click-Control (Get-Edit 3); Send-Text "Me encanta el zorro"
Click-Control (Get-Edit 4); Send-Text "21"
Click-ButtonBelow (Get-Edit 4); Snap $w "completo-6-nota"                # «Añadir nota»
if ((Count-Text "Aún no hay notas para este libro.") -ne 0) { throw "No se ha añadido la nota" }
if (@(Get-Controls $w | Where-Object { $_.Class -eq "Edit" -and $_.Text -eq "Me encanta el zorro" }).Count -ne 1) {
    throw "La nota no aparece en la lista de notas"
}
if ((Count-Like "Nota · pág. 21 · *") -ne 1) { throw "La nota no muestra su tipo y página" }

if (-not (Click-Text $w "← Back")) { if (-not (Click-Text $w "Back")) { throw "No hay botón para volver" } }
Snap $w "completo-7-lista"
if ((Count-Text "Prestado a Ana") -ne 1) { throw "La lista no muestra el nuevo préstamo" }
if ((Count-Text "1 nota") -ne 1) { throw "La lista no muestra la nota nueva" }

# Ajustes: ocultar los préstamos en la lista.
if (-not (Click-Sidebar "Ajustes")) { throw "No está Ajustes en la barra lateral" }
Snap $w "completo-8-ajustes"
if (-not (Click-Text $w "Mostrar préstamos")) { throw "No está el ajuste de préstamos" }
if (-not (Click-Sidebar "Biblioteca")) { throw "No está Biblioteca en la barra lateral" }
Snap $w "completo-9-sin-prestamos"
if ((Count-Like "Prestado a *") -ne 0) { throw "Con el ajuste apagado no debería verse ningún préstamo" }

# Al volver a abrir se conservan los libros, las notas, las fechas y los ajustes.
Stop-Process -Id $app.Id -Force; Start-Sleep -Seconds 2
$app = Start-App "$bin\inkd.exe" "completo2"
if ($app.HasExited) { throw "La app se ha cerrado al volver a abrirla" }
$w = Get-AppWindow $app.Id
Snap $w "completo-10-tras-reiniciar"
if ((Count-Text "1 nota") -ne 1) { throw "No se ha conservado la nota" }
if ((Count-Like "Empezado el *") -ne 2) { throw "No se ha conservado la fecha de inicio" }
if ((Count-Like "Prestado a *") -ne 0) { throw "No se ha conservado el ajuste de préstamos" }

Stop-Process -Id $app.Id -Force
Write-Host "Prueba de Windows (producto completo) superada"
