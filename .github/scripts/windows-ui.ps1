# Prueba de interfaz en Windows: arranca la app, pulsa los controles y guarda
# capturas y la lista de controles en shots/.
# Los textos son controles Static (se buscan por texto); los botones con estilo
# los dibuja SwiftOpenUI (Direct2D). La ventana se coloca siempre en (0,0) con 900x700.
. "$PSScriptRoot/ui.ps1"
# Compilar el producto base: todos los productos comparten la carpeta de compilación,
# así que el inkd.exe que haya puede ser de otro producto (p. ej. windows-ui-completo.ps1).
swift build --product inkd | Out-Null
$bin = swift build --product inkd --show-bin-path

# Empezar sin libros guardados (¡en local borra tu biblioteca de Documentos!).
Remove-Item (Join-Path ([Environment]::GetFolderPath("MyDocuments")) "books.json") -ErrorAction SilentlyContinue

function Count-Text([string]$text) { @(Get-Controls $w | Where-Object { $_.Text -eq $text }).Count }
function Count-Like([string]$pattern) { @(Get-Controls $w | Where-Object { $_.Text -like $pattern }).Count }

# Clic en el botón de marcar de una fila: el botón pequeño (24 px) a la izquierda del título.
function Click-Toggle([string]$title) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $title } | Select-Object -First 1
    if (-not $c) { throw "No hay una fila '$title'" }
    $b = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUICustomButton" -and $_.W -le 32 -and $_.X -lt $c.X } |
        Sort-Object { [math]::Abs(($_.Y + $_.H / 2) - ($c.Y + $c.H / 2)) } | Select-Object -First 1
    if (-not $b) { throw "No hay botón de marcar junto a '$title'" }
    Click-At ($b.X + [int]($b.W / 2)) ($b.Y + [int]($b.H / 2))
}

# Clic en «Añadir libro». Es un botón de texto que SwiftOpenUI dibuja con Direct2D
# (SwiftUID2DSurface, sin texto que buscar): el primero que hay debajo del último campo de texto.
function Click-AddButton {
    $last = Get-Controls $w | Where-Object { $_.Class -eq "Edit" } | Sort-Object Y | Select-Object -Last 1
    if (-not $last) { return $false }
    $b = Get-Controls $w | Where-Object { $_.Class -eq "SwiftUID2DSurface" -and $_.Y -ge ($last.Y + $last.H) } |
        Sort-Object Y | Select-Object -First 1
    if (-not $b) { return $false }
    Click-At ($b.X + [int]($b.W / 2)) ($b.Y + [int]($b.H / 2))
    return $true
}

# Clic en una opción de la barra lateral: el texto más a la izquierda con ese nombre
# (el título de la pantalla también puede llamarse igual).
function Click-Sidebar([string]$text) {
    $c = Get-Controls $w | Where-Object { $_.Text -eq $text -or $_.Text -like "* $text" } |
        Sort-Object X | Select-Object -First 1
    if (-not $c) { return $false }
    Click-At ($c.X + [int]($c.W / 2)) ($c.Y + [int]($c.H / 2))
    return $true
}

$app = Start-App "$bin\inkd.exe" "inkd"
if ($app.HasExited) { throw "La app se ha cerrado al arrancar" }
$w = Get-AppWindow $app.Id
Snap $w "1-inicio"
if ((Count-Text "Cien años de soledad") -ne 1) { throw "No se ve la biblioteca" }
if ((Count-Text "Leyendo") -ne 1) { throw "Al empezar debería haber un libro en Leyendo" }

# Cambiar el estado desde la fila no abre el detalle: El principito pasa de Por leer a Leyendo.
Click-Toggle "El principito"; Snap $w "2-estado-cambiado"
if ((Count-Text "El principito") -ne 1) { throw "Al cambiar el estado se ha salido de la lista" }
if ((Count-Text "Leyendo") -ne 2) { throw "El principito debería estar en Leyendo" }

# Detalle: escribir no debe volver a la lista (fallo de SwiftOpenUI con @Observable, ya arreglado).
if (-not (Click-Text $w "El nombre del viento")) { throw "No está la fila El nombre del viento" }
Snap $w "3-detalle"
if (-not (Click-Class $w "Edit")) { throw "El detalle no tiene campo de título" }
Send-Text "{END} II"; Snap $w "4-detalle-editado"

# Título vacío: aparece el aviso y el libro conserva el último título válido.
if (-not (Click-Class $w "Edit")) { throw "Al escribir se ha salido del detalle" }
Send-Text "{END}+{HOME}{DEL}"; Snap $w "5-titulo-vacio"
if ((Count-Text "El título no puede estar vacío") -ne 1) { throw "No se avisa del título vacío" }
if (-not (Click-Text $w "← Back")) { if (-not (Click-Text $w "Back")) { throw "No hay botón para volver" } }
Snap $w "6-lista-tras-volver"
if ((Count-Text "El nombre del viento II") -ne 1) { throw "La lista no conserva el último título válido" }

# Alta: el primer campo de la biblioteca es el título del formulario «Nuevo libro».
if (-not (Click-Class $w "Edit")) { throw "No está el formulario de alta" }
Send-Text "Dune"
if (-not (Click-AddButton)) { throw "No está el botón Añadir libro" }
Snap $w "7-libro-anadido"
if ((Count-Text "Dune") -ne 1) { throw "No se ha añadido el libro" }

# Ajustes: el producto base no tiene ningún interruptor.
if (-not (Click-Sidebar "Ajustes")) { throw "No está Ajustes en la barra lateral" }
Snap $w "8-ajustes"
if ((Count-Text "Elige qué información se ve en la lista de libros.") -ne 1) { throw "Ajustes no muestra su texto" }
if ((Count-Like "Mostrar *") -ne 0) { throw "El producto base no debería tener interruptores" }
if (-not (Click-Sidebar "Biblioteca")) { throw "No está Biblioteca en la barra lateral" }

# Al volver a abrir se conservan los libros, las ediciones y los estados.
Stop-Process -Id $app.Id -Force; Start-Sleep -Seconds 2
$app = Start-App "$bin\inkd.exe" "inkd2"
if ($app.HasExited) { throw "La app se ha cerrado al volver a abrirla" }
$w = Get-AppWindow $app.Id
Snap $w "9-tras-reiniciar"
if ((Count-Text "El nombre del viento II") -ne 1) { throw "No se ha conservado el título editado" }
if ((Count-Text "Dune") -ne 1) { throw "No se ha conservado el libro añadido" }
if ((Count-Text "Leyendo") -ne 2) { throw "No se ha conservado el cambio de estado" }

Stop-Process -Id $app.Id -Force
Write-Host "Prueba de Windows superada"
