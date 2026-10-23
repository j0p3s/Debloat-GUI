<# : batch
@echo off
REM ---------------------------------------------------------------------------
REM  Debloat GUI - batch/PowerShell hybrid launcher.
REM  cmd.exe runs only these few lines; to PowerShell, this whole header is a
REM  block comment. The batch part passes this file's own path to
REM  Windows PowerShell, which reads the rest of the file (as UTF-8, for the
REM  accented text) and opens the window. Administrator rights are asked
REM  for once (UAC) because removing apps for every user needs them.
REM ---------------------------------------------------------------------------
setlocal
set "DEBLOATGUI_SCRIPT=%~f0"
set "DEBLOATGUI_PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
if exist "%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe" set "DEBLOATGUI_PS=%SystemRoot%\Sysnative\WindowsPowerShell\v1.0\powershell.exe"
if not exist "%DEBLOATGUI_PS%" set "DEBLOATGUI_PS=powershell"
"%DEBLOATGUI_PS%" -NoProfile -ExecutionPolicy Bypass -STA -Command "iex ([IO.File]::ReadAllText($env:DEBLOATGUI_SCRIPT, [Text.Encoding]::UTF8))"
if errorlevel 1 pause
exit /b
#>

# =============================================================================
#  Debloat GUI
#
#  Window with two tabs (Portuguese, English, French and Spanish):
#    Modes          Basic, Standard, Advanced and Ultra, with the description of
#                   each one and the exact list of what applies to this PC
#    Custom         list of the catalog apps, to choose one by one
#
#  Every catalog app has a status:
#    Can be removed   installed (or provisioned) on this PC right now
#    Removed          not installed, and removed earlier with this tool (log)
#    Not installed    not installed: removed by something else, or never there
#  Only the first kind can be ticked and removed.
#
#  Safety:
#    - only apps from a known list (the catalog below) are removed; the Store,
#      App Installer, Windows Security, codecs, Notepad, Paint, Terminal,
#      Snipping Tool and system components are never touched
#    - before removing: confirmation with the list and a restore point (option)
#    - log of the removed apps in %LOCALAPPDATA%\Debloat_GUI
#
#  To add a language: add a code to $Langs / $LangNames, then one more value
#  to every L call (the helper that holds the four texts of a string).
# =============================================================================

$AppVersion = '2.1.0'

$Langs     = @('pt', 'en', 'fr', 'es')
$LangNames = @('Português', 'English', 'Français', 'Español')

# One text in the four languages
function L($pt, $en, $fr, $es) { @{ pt = $pt; en = $en; fr = $fr; es = $es } }

# Language: the saved choice, otherwise the Windows display language, otherwise English
$LangFile = Join-Path $env:LOCALAPPDATA 'Debloat_GUI\language.txt'
$saved = ''
try { $saved = "$(Get-Content -LiteralPath $LangFile -ErrorAction Stop | Select-Object -First 1)".Trim() } catch { }
$script:Lang = if ($Langs -contains $saved) { $saved } else {
    $two = (Get-UICulture).TwoLetterISOLanguageName
    if ($Langs -contains $two) { $two } else { 'en' }
}

# ----------------------------- interface texts -------------------------------
$Str = @{
    title        = L 'Debloat do Windows v{0}' 'Windows Debloat v{0}' 'Debloat de Windows v{0}' 'Debloat de Windows v{0}'
    tabModes     = L 'Modos' 'Modes' 'Modes' 'Modos'
    tabCustom    = L 'Personalizado' 'Custom' 'Personnalisé' 'Personalizado'
    colApp       = L 'App' 'App' 'Application' 'Aplicación'
    colLevel     = L 'Nível' 'Level' 'Niveau' 'Nivel'
    colStatus    = L 'Estado' 'Status' 'État' 'Estado'
    colWhat      = L 'O que é' 'What it is' 'Description' 'Qué es'
    stPresent    = L 'Pode ser removida' 'Can be removed' 'Peut être supprimée' 'Se puede quitar'
    stRemoved    = L 'Removida ({0})' 'Removed ({0})' 'Supprimée ({0})' 'Quitada ({0})'
    stAbsent     = L 'Não instalada' 'Not installed' 'Non installée' 'No instalada'
    filterLbl    = L 'Mostrar:' 'Show:' 'Afficher :' 'Mostrar:'
    fAll         = L 'Todas' 'All' 'Toutes' 'Todas'
    fRemovable   = L 'Só as que podem ser removidas' 'Only those that can be removed' 'Seulement celles qui peuvent être supprimées' 'Solo las que se pueden quitar'
    fGone        = L 'Já removidas / não instaladas' 'Already removed / not installed' 'Déjà supprimées / non installées' 'Ya quitadas / no instaladas'
    restore      = L 'Criar ponto de restauro antes (recomendado)' 'Create a restore point first (recommended)' 'Créer un point de restauration avant (recommandé)' 'Crear un punto de restauración antes (recomendado)'
    btnMode      = L 'Remover {0} apps (modo {1})' 'Remove {0} apps ({1} mode)' 'Supprimer {0} applications (mode {1})' 'Quitar {0} apps (modo {1})'
    customHint   = L 'Marca o que queres remover. As apps já removidas ou não instaladas aparecem a cinzento e não podem ser marcadas. Os botões marcam tudo até esse modo.' 'Tick what you want to remove. Apps that are already removed or not installed are greyed out and cannot be ticked. The buttons tick everything up to that mode.' 'Cochez ce que vous voulez supprimer. Les applications déjà supprimées ou non installées sont en gris et ne peuvent pas être cochées. Les boutons cochent tout jusqu''à ce mode.' 'Marque lo que quiera quitar. Las apps ya quitadas o no instaladas aparecen en gris y no se pueden marcar. Los botones marcan todo hasta ese modo.'
    upTo         = L 'Até {0}' 'Up to {0}' 'Jusqu''à {0}' 'Hasta {0}'
    untick       = L 'Desmarcar tudo' 'Untick all' 'Tout décocher' 'Desmarcar todo'
    btnCustom    = L 'Remover selecionadas ({0})' 'Remove selected ({0})' 'Supprimer la sélection ({0})' 'Quitar seleccionadas ({0})'
    star         = L '  ★ recomendado' '  ★ recommended' '  ★ recommandé' '  ★ recomendado'
    modeLine2    = L '{0} apps a remover' '{0} apps to remove' '{0} apps à supprimer' '{0} apps por quitar'
    summary      = L '{0} podem ser removidas  |  {1} removidas com este programa  |  {2} não instaladas (já removidas ou nunca instaladas)' '{0} can be removed  |  {1} removed with this tool  |  {2} not installed (already removed or never installed)' '{0} peuvent être supprimées  |  {1} supprimées avec cet outil  |  {2} non installées (déjà supprimées ou jamais installées)' '{0} se pueden quitar  |  {1} quitadas con esta herramienta  |  {2} no instaladas (ya quitadas o nunca instaladas)'
    analyzing    = L 'A analisar as apps instaladas...' 'Scanning the installed apps...' 'Analyse des applications installées...' 'Analizando las aplicaciones instaladas...'
    found        = L '{0} podem ser removidas, {1} já removidas ou ausentes (catálogo: {2} apps).' '{0} can be removed, {1} already removed or absent (catalog: {2} apps).' '{0} peuvent être supprimées, {1} déjà supprimées ou absentes (catalogue : {2} applications).' '{0} se pueden quitar, {1} ya quitadas o ausentes (catálogo: {2} apps).'
    nothing      = L 'Nada para remover.' 'Nothing to remove.' 'Rien à supprimer.' 'Nada que quitar.'
    confirmTitle = L 'Confirmar' 'Confirm' 'Confirmer' 'Confirmar'
    confirmHead  = L 'Vão ser removidas ({0}):' 'These will be removed ({0}):' 'Ces applications vont être supprimées ({0}) :' 'Se quitarán estas apps ({0}):'
    confirmAsk   = L 'Continuar?' 'Continue?' 'Continuer ?' '¿Continuar?'
    xboxWarn     = L 'ATENÇÃO: inclui o início de sessão Xbox. Jogos do Game Pass / Microsoft Store e jogos com conta Xbox deixam de funcionar.' 'WARNING: this includes Xbox sign-in. Game Pass / Microsoft Store games and games that use an Xbox account will stop working.' 'ATTENTION : cela inclut la connexion Xbox. Les jeux Game Pass / Microsoft Store et les jeux avec compte Xbox ne fonctionneront plus.' 'ATENCIÓN: incluye el inicio de sesión de Xbox. Los juegos de Game Pass / Microsoft Store y los juegos con cuenta Xbox dejarán de funcionar.'
    cancelled    = L 'Cancelado: nada foi alterado.' 'Cancelled: nothing was changed.' 'Annulé : rien n''a été modifié.' 'Cancelado: no se cambió nada.'
    restoring    = L 'A criar ponto de restauro (pode demorar um minuto)...' 'Creating a restore point (it can take a minute)...' 'Création du point de restauration (cela peut prendre une minute)...' 'Creando el punto de restauración (puede tardar un minuto)...'
    rpName       = L 'Antes do Debloat GUI' 'Before Debloat GUI' 'Avant Debloat GUI' 'Antes de Debloat GUI'
    restoreOk    = L 'Ponto de restauro criado: "{0}".' 'Restore point created: "{0}".' 'Point de restauration créé : "{0}".' 'Punto de restauración creado: "{0}".'
    restoreFail  = L 'Não foi criado ponto de restauro (Proteção do Sistema desligada, ou já foi criado um nas últimas 24 horas).' 'No restore point was created (System Protection is off, or one was already created in the last 24 hours).' 'Aucun point de restauration n''a été créé (Protection du système désactivée, ou un point a déjà été créé dans les dernières 24 heures).' 'No se creó el punto de restauración (la Protección del sistema está desactivada, o ya se creó uno en las últimas 24 horas).'
    restoreAsk   = L 'Não foi possível criar um ponto de restauro. Continuar mesmo assim?' 'A restore point could not be created. Continue anyway?' 'Impossible de créer un point de restauration. Continuer quand même ?' 'No se pudo crear un punto de restauración. ¿Continuar de todos modos?'
    restoreTitle = L 'Ponto de restauro' 'Restore point' 'Point de restauration' 'Punto de restauración'
    removing     = L 'A remover: {0}' 'Removing: {0}' 'Suppression : {0}' 'Quitando: {0}'
    failedLog    = L '   falhou {0}: {1}' '   failed {0}: {1}' '   échec {0} : {1}' '   falló {0}: {1}'
    failedProv   = L '   falhou (provisionada) {0}: {1}' '   failed (provisioned) {0}: {1}' '   échec (préinstallée) {0} : {1}' '   falló (aprovisionada) {0}: {1}'
    logRemoved   = L 'Removidas (reinstalam-se a partir da Microsoft Store):' 'Removed (they can be reinstalled from the Microsoft Store):' 'Supprimées (réinstallables depuis le Microsoft Store) :' 'Quitadas (se reinstalan desde Microsoft Store):'
    logFailed    = L 'Falharam:' 'Failed:' 'Échecs :' 'Fallaron:'
    logPath      = L 'Registo: {0}' 'Log: {0}' 'Journal : {0}' 'Registro: {0}'
    done         = L '>>> Concluído: {0} removidas, {1} com falhas. Reinicia o PC para terminar. <<<' '>>> Finished: {0} removed, {1} failed. Restart the PC to finish. <<<' '>>> Terminé : {0} supprimées, {1} en échec. Redémarrez le PC pour terminer. <<<' '>>> Terminado: {0} quitadas, {1} con errores. Reinicie el PC para terminar. <<<'
    doneBox      = L '{0} removidas, {1} com falhas.' '{0} removed, {1} failed.' '{0} supprimées, {1} en échec.' '{0} quitadas, {1} con errores.'
    restartMsg   = L 'Reinicia o PC para terminar.' 'Restart the PC to finish.' 'Redémarrez le PC pour terminer.' 'Reinicie el PC para terminar.'
    doneTitle    = L 'Concluído' 'Finished' 'Terminé' 'Terminado'
    errLog       = L 'ERRO: {0}' 'ERROR: {0}' 'ERREUR : {0}' 'ERROR: {0}'
    errBox       = L 'Erro: {0}' 'Error: {0}' 'Erreur : {0}' 'Error: {0}'
    unexpected   = L 'Erro inesperado: {0}{1}Linha {2}: {3}' 'Unexpected error: {0}{1}Line {2}: {3}' 'Erreur inattendue : {0}{1}Ligne {2} : {3}' 'Error inesperado: {0}{1}Línea {2}: {3}'
    noAdmin      = L 'Sem permissao de administrador: nada foi alterado.' 'No administrator permission: nothing was changed.' 'Pas d''autorisation administrateur : rien n''a été modifié.' 'Sin permiso de administrador: no se cambió nada.'
    modeName     = L 'Modo {0}' '{0} mode' 'Mode {0}' 'Modo {0}'
    customName   = L 'Seleção personalizada' 'Custom selection' 'Sélection personnalisée' 'Selección personalizada'
    logHeader    = L 'Debloat GUI - {0} - {1}' 'Debloat GUI - {0} - {1}' 'Debloat GUI - {0} - {1}' 'Debloat GUI - {0} - {1}'
    intro1       = L '- Só são removidas apps de uma lista conhecida. Nunca são tocados: Microsoft Store, Instalador de Aplicações (winget), Segurança do Windows, codecs, Bloco de Notas, Paint, Terminal, Ferramenta de Recorte e componentes do sistema.' '- Only apps from a known list are removed. These are never touched: Microsoft Store, App Installer (winget), Windows Security, codecs, Notepad, Paint, Terminal, Snipping Tool and system components.' '- Seules les applications d''une liste connue sont supprimées. Ne sont jamais touchés : Microsoft Store, Programme d''installation d''applications (winget), Sécurité Windows, codecs, Bloc-notes, Paint, Terminal, Outil Capture d''écran et composants système.' '- Solo se quitan apps de una lista conocida. Nunca se tocan: Microsoft Store, Instalador de aplicación (winget), Seguridad de Windows, códecs, Bloc de notas, Paint, Terminal, Herramienta de recortes y componentes del sistema.'
    intro2       = L '- Antes de remover vês a lista e confirmas; é criado um ponto de restauro (opção). As apps removidas reinstalam-se a partir da Microsoft Store.' '- Before removing you see the list and confirm; a restore point is created (option). Removed apps can be reinstalled from the Microsoft Store.' '- Avant la suppression, vous voyez la liste et vous confirmez ; un point de restauration est créé (option). Les applications supprimées se réinstallent depuis le Microsoft Store.' '- Antes de quitar ve la lista y confirma; se crea un punto de restauración (opción). Las apps quitadas se reinstalan desde Microsoft Store.'
    intro3       = L '- Remover apps liberta espaço e limpa o menu Iniciar. O maior ganho de desempenho vem do que corre em segundo plano (Widgets, Teams, Ligação ao Telemóvel, OneDrive: modos Avançado e Ultra) e das apps de arranque e serviços (Windows_Debloat.cmd).' '- Removing apps frees space and cleans the Start menu. The biggest performance gain comes from what runs in the background (Widgets, Teams, Phone Link, OneDrive: Advanced and Ultra modes) and from startup apps and services (Windows_Debloat.cmd).' '- Supprimer des applications libère de l''espace et nettoie le menu Démarrer. Le plus gros gain de performance vient de ce qui tourne en arrière-plan (Widgets, Teams, Liaison avec le téléphone, OneDrive : modes Avancé et Ultra) et des applications de démarrage et des services (Windows_Debloat.cmd).' '- Quitar apps libera espacio y limpia el menú Inicio. La mayor mejora de rendimiento viene de lo que se ejecuta en segundo plano (Widgets, Teams, Enlace a Móvil, OneDrive: modos Avanzado y Ultra) y de las apps de inicio y los servicios (Windows_Debloat.cmd).'
}

function Tx([string]$k) {
    $s = $Str[$k][$script:Lang]
    if (-not $s) { $s = $Str[$k]['en'] }
    if ($args.Count) { $s -f $args } else { $s }
}

# Levels: each mode removes its own level and all the previous ones
$Tiers = @{
    1 = @{ Name = L 'Básico' 'Basic' 'Basique' 'Básico'
           Tag  = L '100% seguro' '100% safe' '100 % sûr' '100% seguro'
           Rgb  = @(40, 167, 69)
           Desc = L 'Remove só publicidade: jogos e apps patrocinadas instaladas pelo Windows ou pelo fabricante (Candy Crush, TikTok, Facebook, Instagram...) e o atalho de publicidade do Microsoft 365. Não toca em nenhuma app da Microsoft que uses.' `
                    'Removes advertising only: games and sponsored apps installed by Windows or the manufacturer (Candy Crush, TikTok, Facebook, Instagram...) and the Microsoft 365 promotion shortcut. It does not touch any Microsoft app you use.' `
                    'Supprime uniquement la publicité : jeux et applications sponsorisées installés par Windows ou le fabricant (Candy Crush, TikTok, Facebook, Instagram...) et le raccourci publicitaire de Microsoft 365. Ne touche à aucune application Microsoft que vous utilisez.' `
                    'Quita solo la publicidad: juegos y apps patrocinadas instaladas por Windows o por el fabricante (Candy Crush, TikTok, Facebook, Instagram...) y el acceso directo publicitario de Microsoft 365. No toca ninguna app de Microsoft que use.' }
    2 = @{ Name = L 'Standard' 'Standard' 'Standard' 'Estándar'
           Tag  = L 'equilibrado' 'balanced' 'équilibré' 'equilibrado'
           Rgb  = @(59, 130, 246)
           Desc = L 'Básico + apps da Microsoft que quase ninguém usa ou que foram descontinuadas (Notícias, Meteorologia, Mapas, Dicas, Solitaire, Skype, Correio e Calendário, Cortana, Paint 3D, Filmes e TV...) e apps de streaming pré-instaladas (Spotify, Netflix, Disney+, Prime Video).' `
                    'Basic + Microsoft apps that almost nobody uses or that were discontinued (News, Weather, Maps, Tips, Solitaire, Skype, Mail and Calendar, Cortana, Paint 3D, Movies & TV...) and pre-installed streaming apps (Spotify, Netflix, Disney+, Prime Video).' `
                    'Basique + applications Microsoft que presque personne n''utilise ou qui ont été abandonnées (Actualités, Météo, Cartes, Astuces, Solitaire, Skype, Courrier et Calendrier, Cortana, Paint 3D, Films et TV...) et applications de streaming préinstallées (Spotify, Netflix, Disney+, Prime Video).' `
                    'Básico + apps de Microsoft que casi nadie usa o que se han descontinuado (Noticias, El Tiempo, Mapas, Consejos, Solitario, Skype, Correo y Calendario, Cortana, Paint 3D, Películas y TV...) y apps de streaming preinstaladas (Spotify, Netflix, Disney+, Prime Video).' }
    3 = @{ Name = L 'Avançado' 'Advanced' 'Avancé' 'Avanzado'
           Tag  = L 'recomendado para gaming' 'recommended for gaming' 'recommandé pour le gaming' 'recomendado para juegos'
           Rgb  = @(253, 126, 20)
           Desc = L 'Standard + apps que correm em segundo plano ou arrancam com o Windows (Widgets, Ligação ao Telemóvel, Teams, Copilot) e apps secundárias (Outlook novo, OneNote para Windows 10, To Do, Gravador de Som, Assistência Rápida). Mantém o Xbox, a Calculadora, a Câmara e as Fotografias.' `
                    'Standard + apps that run in the background or start with Windows (Widgets, Phone Link, Teams, Copilot) and secondary apps (new Outlook, OneNote for Windows 10, To Do, Sound Recorder, Quick Assist). Keeps Xbox, Calculator, Camera and Photos.' `
                    'Standard + applications qui tournent en arrière-plan ou démarrent avec Windows (Widgets, Liaison avec le téléphone, Teams, Copilot) et applications secondaires (nouveau Outlook, OneNote pour Windows 10, To Do, Enregistreur vocal, Assistance rapide). Conserve Xbox, la Calculatrice, la Caméra et Photos.' `
                    'Estándar + apps que se ejecutan en segundo plano o arrancan con Windows (Widgets, Enlace a Móvil, Teams, Copilot) y apps secundarias (nuevo Outlook, OneNote para Windows 10, To Do, Grabadora de sonidos, Asistencia rápida). Mantiene Xbox, la Calculadora, la Cámara y Fotos.' }
    4 = @{ Name = L 'Ultra' 'Ultra' 'Ultra' 'Ultra'
           Tag  = L 'máximo dos máximos' 'maximum' 'maximum' 'máximo'
           Rgb  = @(220, 53, 69)
           Desc = L 'Avançado + tudo o que se pode remover sem partir o Windows: o Xbox inteiro (app, Game Bar e início de sessão Xbox), Calculadora, Câmara, Fotografias, Leitor Multimédia, Alarmes e Relógio, Notas Autoadesivas e o OneDrive. ATENÇÃO: jogos do Game Pass / Microsoft Store e jogos com conta Xbox (Minecraft, Forza, Sea of Thieves...) deixam de funcionar.' `
                    'Advanced + everything that can be removed without breaking Windows: all of Xbox (app, Game Bar and Xbox sign-in), Calculator, Camera, Photos, Media Player, Alarms & Clock, Sticky Notes and OneDrive. WARNING: Game Pass / Microsoft Store games and games that use an Xbox account (Minecraft, Forza, Sea of Thieves...) will stop working.' `
                    'Avancé + tout ce qui peut être supprimé sans casser Windows : tout Xbox (application, Game Bar et connexion Xbox), Calculatrice, Caméra, Photos, Lecteur multimédia, Alarmes et horloge, Pense-bêtes et OneDrive. ATTENTION : les jeux Game Pass / Microsoft Store et les jeux avec compte Xbox (Minecraft, Forza, Sea of Thieves...) ne fonctionneront plus.' `
                    'Avanzado + todo lo que se puede quitar sin romper Windows: todo Xbox (app, Game Bar e inicio de sesión de Xbox), Calculadora, Cámara, Fotos, Reproductor multimedia, Alarmas y reloj, Notas rápidas y OneDrive. ATENCIÓN: los juegos de Game Pass / Microsoft Store y los juegos con cuenta Xbox (Minecraft, Forza, Sea of Thieves...) dejarán de funcionar.' }
}
function TierName([int]$t) { $Tiers[$t].Name[$script:Lang] }
function TierTag([int]$t)  { $Tiers[$t].Tag[$script:Lang] }
function TierDesc([int]$t) { $Tiers[$t].Desc[$script:Lang] }

# ----------------------------- catalog ---------------------------------------
# N = name, D = what it is (both in four languages), P = package names (accepts *), T = level
$dAdGame   = L 'Jogos instalados como publicidade.' 'Games installed as advertising.' 'Jeux installés à titre publicitaire.' 'Juegos instalados como publicidad.'
$dAdSocial = L 'Rede social instalada como publicidade.' 'Social network installed as advertising.' 'Réseau social installé à titre publicitaire.' 'Red social instalada como publicidad.'

$Catalog = @(
    # --- 1. Basic: advertising ---
    @{ N = L 'Jogos King (Candy Crush, Bubble Witch...)' 'King games (Candy Crush, Bubble Witch...)' 'Jeux King (Candy Crush, Bubble Witch...)' 'Juegos de King (Candy Crush, Bubble Witch...)'; T = 1; P = @('king.com.*'); D = $dAdGame }
    @{ N = L 'Jogos Gameloft (March of Empires, Asphalt...)' 'Gameloft games (March of Empires, Asphalt...)' 'Jeux Gameloft (March of Empires, Asphalt...)' 'Juegos de Gameloft (March of Empires, Asphalt...)'; T = 1; P = @('A278AB0D.*', 'GAMELOFTSA.*'); D = $dAdGame }
    @{ N = L 'Jogos de casino e sociais (Zynga, Playtika)' 'Casino and social games (Zynga, Playtika)' 'Jeux de casino et sociaux (Zynga, Playtika)' 'Juegos de casino y sociales (Zynga, Playtika)'; T = 1; P = @('*Zynga*', 'Playtika*'); D = $dAdGame }
    @{ N = L 'TikTok' 'TikTok' 'TikTok' 'TikTok'; T = 1; P = @('BytedancePte.Ltd.TikTok'); D = $dAdSocial }
    @{ N = L 'Facebook' 'Facebook' 'Facebook' 'Facebook'; T = 1; P = @('Facebook.Facebook*'); D = $dAdSocial }
    @{ N = L 'Instagram' 'Instagram' 'Instagram' 'Instagram'; T = 1; P = @('Facebook.Instagram*'); D = $dAdSocial }
    @{ N = L 'X (Twitter)' 'X (Twitter)' 'X (Twitter)' 'X (Twitter)'; T = 1; P = @('9E2F88E3.Twitter'); D = $dAdSocial }
    @{ N = L 'LinkedIn' 'LinkedIn' 'LinkedIn' 'LinkedIn'; T = 1; P = @('7EE7776C.LinkedInforWindows'); D = $dAdSocial }
    @{ N = L 'Outras apps promocionais' 'Other promotional apps' 'Autres applications promotionnelles' 'Otras apps promocionales'; T = 1
       P = @('*.AdobePhotoshopExpress', '*Duolingo*', 'PandoraMediaInc.*', 'Flipboard.Flipboard', 'ShazamEntertainmentLtd.Shazam', 'ClearChannelRadioDigital.iHeartRadio')
       D = L 'Photoshop Express, Duolingo, Pandora, Flipboard, Shazam, iHeartRadio.' 'Photoshop Express, Duolingo, Pandora, Flipboard, Shazam, iHeartRadio.' 'Photoshop Express, Duolingo, Pandora, Flipboard, Shazam, iHeartRadio.' 'Photoshop Express, Duolingo, Pandora, Flipboard, Shazam, iHeartRadio.' }
    @{ N = L 'McAfee (app da Store)' 'McAfee (Store app)' 'McAfee (application du Store)' 'McAfee (app de la Store)'; T = 1; P = @('5A894077.McAfeeSecurity')
       D = L 'Oferta de antivírus. O Windows Security já protege o PC.' 'Antivirus trial offer. Windows Security already protects the PC.' 'Offre d''antivirus. Sécurité Windows protège déjà le PC.' 'Oferta de antivirus. Seguridad de Windows ya protege el equipo.' }
    @{ N = L 'Oferta Dropbox' 'Dropbox offer' 'Offre Dropbox' 'Oferta de Dropbox'; T = 1; P = @('C27EB4BA.DropboxOEM')
       D = L 'Promoção do Dropbox instalada pelo fabricante.' 'Dropbox promotion installed by the manufacturer.' 'Promotion Dropbox installée par le fabricant.' 'Promoción de Dropbox instalada por el fabricante.' }
    @{ N = L 'Microsoft 365 (Office) hub' 'Microsoft 365 (Office) hub' 'Hub Microsoft 365 (Office)' 'Centro de Microsoft 365 (Office)'; T = 1; P = @('Microsoft.MicrosoftOfficeHub')
       D = L 'Atalho e publicidade do Microsoft 365. O Office instalado não é afetado.' 'Microsoft 365 shortcut and advertising. The installed Office is not affected.' 'Raccourci et publicité Microsoft 365. L''Office installé n''est pas affecté.' 'Acceso directo y publicidad de Microsoft 365. El Office instalado no se ve afectado.' }
    # --- 2. Standard: little-used Microsoft apps ---
    @{ N = L 'Notícias (MSN)' 'News (MSN)' 'Actualités (MSN)' 'Noticias (MSN)'; T = 2; P = @('Microsoft.BingNews')
       D = L 'App de notícias.' 'News app.' 'Application d''actualités.' 'App de noticias.' }
    @{ N = L 'Meteorologia' 'Weather' 'Météo' 'El Tiempo'; T = 2; P = @('Microsoft.BingWeather')
       D = L 'App do tempo.' 'Weather app.' 'Application météo.' 'App del tiempo.' }
    @{ N = L 'Desporto, Finanças, Viagens, Receitas, Saúde' 'Sports, Finance, Travel, Food & Drink, Health' 'Sport, Finance, Voyages, Cuisine, Santé' 'Deportes, Finanzas, Viajes, Recetas, Salud'; T = 2
       P = @('Microsoft.BingSports', 'Microsoft.BingFinance', 'Microsoft.BingTravel', 'Microsoft.BingFoodAndDrink', 'Microsoft.BingHealthAndFitness')
       D = L 'Apps antigas da MSN.' 'Old MSN apps.' 'Anciennes applications MSN.' 'Apps antiguas de MSN.' }
    @{ N = L 'Mapas' 'Maps' 'Cartes' 'Mapas'; T = 2; P = @('Microsoft.WindowsMaps')
       D = L 'App de mapas.' 'Maps app.' 'Application de cartes.' 'App de mapas.' }
    @{ N = L 'Dicas' 'Tips' 'Astuces' 'Consejos'; T = 2; P = @('Microsoft.Getstarted')
       D = L 'Dicas do Windows.' 'Windows tips.' 'Astuces Windows.' 'Consejos de Windows.' }
    @{ N = L 'Hub de Comentários' 'Feedback Hub' 'Hub de commentaires' 'Centro de opiniones'; T = 2; P = @('Microsoft.WindowsFeedbackHub')
       D = L 'Envia comentários à Microsoft.' 'Sends feedback to Microsoft.' 'Envoie des commentaires à Microsoft.' 'Envía comentarios a Microsoft.' }
    @{ N = L 'Microsoft Solitaire Collection' 'Microsoft Solitaire Collection' 'Microsoft Solitaire Collection' 'Microsoft Solitaire Collection'; T = 2; P = @('Microsoft.MicrosoftSolitaireCollection')
       D = L 'Jogos de cartas com publicidade.' 'Card games with ads.' 'Jeux de cartes avec publicités.' 'Juegos de cartas con publicidad.' }
    @{ N = L 'Pessoas' 'People' 'Contacts' 'Contactos'; T = 2; P = @('Microsoft.People')
       D = L 'App de contactos.' 'Contacts app.' 'Application de contacts.' 'App de contactos.' }
    @{ N = L 'Correio e Calendário' 'Mail and Calendar' 'Courrier et Calendrier' 'Correo y Calendario'; T = 2; P = @('microsoft.windowscommunicationsapps')
       D = L 'Descontinuada pela Microsoft e substituída pelo novo Outlook.' 'Discontinued by Microsoft and replaced by the new Outlook.' 'Abandonnée par Microsoft et remplacée par le nouvel Outlook.' 'Descontinuada por Microsoft y sustituida por el nuevo Outlook.' }
    @{ N = L 'Skype' 'Skype' 'Skype' 'Skype'; T = 2; P = @('Microsoft.SkypeApp')
       D = L 'A Microsoft encerrou o Skype em maio de 2025.' 'Microsoft shut Skype down in May 2025.' 'Microsoft a fermé Skype en mai 2025.' 'Microsoft cerró Skype en mayo de 2025.' }
    @{ N = L 'Cortana' 'Cortana' 'Cortana' 'Cortana'; T = 2; P = @('Microsoft.549981C3F5F10')
       D = L 'Assistente de voz descontinuada.' 'Discontinued voice assistant.' 'Assistant vocal abandonné.' 'Asistente de voz descontinuado.' }
    @{ N = L 'Visualizador 3D, Paint 3D e Print 3D' '3D Viewer, Paint 3D and Print 3D' 'Visionneuse 3D, Paint 3D et Print 3D' 'Visor 3D, Paint 3D y Print 3D'; T = 2
       P = @('Microsoft.Microsoft3DViewer', 'Microsoft.MSPaint', 'Microsoft.Print3D')
       D = L 'Apps 3D. O Paint normal é outra app e fica.' '3D apps. The regular Paint is a different app and stays.' 'Applications 3D. Le Paint classique est une autre application et reste.' 'Apps 3D. El Paint normal es otra app y se queda.' }
    @{ N = L 'Portal de Realidade Mista' 'Mixed Reality Portal' 'Portail de réalité mixte' 'Portal de realidad mixta'; T = 2; P = @('Microsoft.MixedReality.Portal')
       D = L 'Só serve para óculos de realidade mista.' 'Only useful with mixed reality headsets.' 'Utile seulement avec un casque de réalité mixte.' 'Solo sirve para gafas de realidad mixta.' }
    @{ N = L 'Filmes e TV' 'Movies & TV' 'Films et TV' 'Películas y TV'; T = 2; P = @('Microsoft.ZuneVideo')
       D = L 'Leitor e loja de vídeo. O Leitor Multimédia abre os mesmos ficheiros.' 'Video player and store. Media Player opens the same files.' 'Lecteur et boutique de vidéos. Le Lecteur multimédia ouvre les mêmes fichiers.' 'Reproductor y tienda de vídeo. El Reproductor multimedia abre los mismos archivos.' }
    @{ N = L 'Pagamentos, Mensagens e Planos Móveis' 'Wallet, Messaging and Mobile Plans' 'Portefeuille, Messagerie et Forfaits mobiles' 'Cartera, Mensajes y Planes móviles'; T = 2
       P = @('Microsoft.Wallet', 'Microsoft.Messaging', 'Microsoft.OneConnect')
       D = L 'Apps antigas sem uso.' 'Old apps nobody uses.' 'Anciennes applications inutilisées.' 'Apps antiguas sin uso.' }
    @{ N = L 'Power Automate' 'Power Automate' 'Power Automate' 'Power Automate'; T = 2; P = @('Microsoft.PowerAutomateDesktop')
       D = L 'Automação para utilizadores avançados.' 'Automation for advanced users.' 'Automatisation pour utilisateurs avancés.' 'Automatización para usuarios avanzados.' }
    @{ N = L 'Dev Home' 'Dev Home' 'Dev Home' 'Dev Home'; T = 2; P = @('Microsoft.Windows.DevHome')
       D = L 'Painel para programadores.' 'Dashboard for developers.' 'Tableau de bord pour développeurs.' 'Panel para desarrolladores.' }
    @{ N = L 'Journal' 'Journal' 'Journal' 'Journal'; T = 2; P = @('Microsoft.MicrosoftJournal')
       D = L 'Notas com caneta.' 'Notes with a pen.' 'Notes au stylet.' 'Notas con lápiz.' }
    @{ N = L 'Clipchamp' 'Clipchamp' 'Clipchamp' 'Clipchamp'; T = 2; P = @('Clipchamp.Clipchamp')
       D = L 'Editor de vídeo instalado com o Windows.' 'Video editor installed with Windows.' 'Éditeur vidéo installé avec Windows.' 'Editor de vídeo instalado con Windows.' }
    @{ N = L 'Apps de streaming (Spotify, Netflix, Disney+, Prime Video)' 'Streaming apps (Spotify, Netflix, Disney+, Prime Video)' 'Applications de streaming (Spotify, Netflix, Disney+, Prime Video)' 'Apps de streaming (Spotify, Netflix, Disney+, Prime Video)'; T = 2
       P = @('SpotifyAB.SpotifyMusic', '4DF9E0F8.Netflix', 'Disney.37853FC22B2CE', 'AmazonVideo.PrimeVideo')
       D = L 'Remove só se não as usares neste PC.' 'Remove only if you do not use them on this PC.' 'Ne supprimez que si vous ne les utilisez pas sur ce PC.' 'Quite solo si no las usa en este PC.' }
    # --- 3. Advanced: background and secondary apps ---
    @{ N = L 'Widgets' 'Widgets' 'Widgets' 'Widgets'; T = 3; P = @('MicrosoftWindows.Client.WebExperience')
       D = L 'Painel de notícias e tempo; corre em segundo plano e gasta RAM.' 'News and weather panel; runs in the background and uses RAM.' 'Panneau d''actualités et de météo ; tourne en arrière-plan et consomme de la RAM.' 'Panel de noticias y tiempo; se ejecuta en segundo plano y gasta RAM.' }
    @{ N = L 'Ligação ao Telemóvel (Phone Link)' 'Phone Link' 'Liaison avec le téléphone (Phone Link)' 'Enlace a Móvil (Phone Link)'; T = 3; P = @('Microsoft.YourPhone')
       D = L 'Liga o telemóvel ao PC; corre em segundo plano.' 'Connects the phone to the PC; runs in the background.' 'Relie le téléphone au PC ; tourne en arrière-plan.' 'Conecta el móvil al PC; se ejecuta en segundo plano.' }
    @{ N = L 'Copilot' 'Copilot' 'Copilot' 'Copilot'; T = 3; P = @('Microsoft.Copilot')
       D = L 'Assistente de IA.' 'AI assistant.' 'Assistant IA.' 'Asistente de IA.' }
    @{ N = L 'Microsoft Teams' 'Microsoft Teams' 'Microsoft Teams' 'Microsoft Teams'; T = 3; P = @('MicrosoftTeams', 'MSTeams')
       D = L 'Arranca com o Windows e fica em segundo plano.' 'Starts with Windows and stays in the background.' 'Démarre avec Windows et reste en arrière-plan.' 'Arranca con Windows y se queda en segundo plano.' }
    @{ N = L 'Outlook (novo)' 'Outlook (new)' 'Outlook (nouveau)' 'Outlook (nuevo)'; T = 3; P = @('Microsoft.OutlookForWindows')
       D = L 'App de email.' 'Email app.' 'Application de messagerie.' 'App de correo.' }
    @{ N = L 'OneNote para Windows 10' 'OneNote for Windows 10' 'OneNote pour Windows 10' 'OneNote para Windows 10'; T = 3; P = @('Microsoft.Office.OneNote')
       D = L 'OneNote antigo. O OneNote do Microsoft 365 é outro programa.' 'Old OneNote. The OneNote in Microsoft 365 is a different program.' 'Ancien OneNote. Le OneNote de Microsoft 365 est un autre programme.' 'OneNote antiguo. El OneNote de Microsoft 365 es otro programa.' }
    @{ N = L 'Microsoft To Do' 'Microsoft To Do' 'Microsoft To Do' 'Microsoft To Do'; T = 3; P = @('Microsoft.Todos')
       D = L 'Lista de tarefas.' 'Task list.' 'Liste de tâches.' 'Lista de tareas.' }
    @{ N = L 'Obter Ajuda' 'Get Help' 'Obtenir de l''aide' 'Obtener ayuda'; T = 3; P = @('Microsoft.GetHelp')
       D = L 'Suporte da Microsoft; os solucionadores de problemas do Windows 11 usam-na.' 'Microsoft support; the Windows 11 troubleshooters use it.' 'Support Microsoft ; les utilitaires de résolution des problèmes de Windows 11 l''utilisent.' 'Soporte de Microsoft; los solucionadores de problemas de Windows 11 la usan.' }
    @{ N = L 'Segurança Familiar' 'Family Safety' 'Sécurité familiale' 'Seguridad familiar'; T = 3; P = @('MicrosoftCorporationII.MicrosoftFamily')
       D = L 'Controlo parental.' 'Parental controls.' 'Contrôle parental.' 'Control parental.' }
    @{ N = L 'Gravador de Som' 'Sound Recorder' 'Enregistreur vocal' 'Grabadora de sonidos'; T = 3; P = @('Microsoft.WindowsSoundRecorder')
       D = L 'Gravador de áudio simples.' 'Simple audio recorder.' 'Enregistreur audio simple.' 'Grabadora de audio sencilla.' }
    @{ N = L 'Assistência Rápida' 'Quick Assist' 'Assistance rapide' 'Asistencia rápida'; T = 3; P = @('MicrosoftCorporationII.QuickAssist')
       D = L 'Suporte remoto. Reinstala-se da Store se precisares.' 'Remote support. You can reinstall it from the Store if you need it.' 'Assistance à distance. Se réinstalle depuis le Store si besoin.' 'Soporte remoto. Se reinstala desde la Store si lo necesita.' }
    @{ N = L 'Xbox Console Companion e voz para texto' 'Xbox Console Companion and speech to text' 'Xbox Console Companion et reconnaissance vocale' 'Xbox Console Companion y voz a texto'; T = 3
       P = @('Microsoft.XboxApp', 'Microsoft.XboxSpeechToTextOverlay')
       D = L 'App Xbox antiga (substituída pela atual) e ditado do chat de grupo.' 'Old Xbox app (replaced by the current one) and group chat dictation.' 'Ancienne application Xbox (remplacée par l''actuelle) et dictée du chat de groupe.' 'App Xbox antigua (sustituida por la actual) y dictado del chat de grupo.' }
    # --- 4. Ultra: the maximum ---
    @{ N = L 'App Xbox' 'Xbox app' 'Application Xbox' 'App de Xbox'; T = 4; P = @('Microsoft.GamingApp')
       D = L 'Necessária para o PC Game Pass e jogos da Microsoft Store.' 'Needed for PC Game Pass and Microsoft Store games.' 'Nécessaire pour PC Game Pass et les jeux du Microsoft Store.' 'Necesaria para PC Game Pass y los juegos de Microsoft Store.' }
    @{ N = L 'Xbox Game Bar' 'Xbox Game Bar' 'Xbox Game Bar' 'Xbox Game Bar'; T = 4; P = @('Microsoft.XboxGamingOverlay', 'Microsoft.XboxGameOverlay')
       D = L 'Overlay Win+G: gravações e widgets de desempenho.' 'Win+G overlay: recordings and performance widgets.' 'Surimpression Win+G : enregistrements et widgets de performances.' 'Superposición Win+G: grabaciones y widgets de rendimiento.' }
    @{ N = L 'Início de sessão Xbox' 'Xbox sign-in' 'Connexion Xbox' 'Inicio de sesión de Xbox'; T = 4; P = @('Microsoft.XboxIdentityProvider', 'Microsoft.Xbox.TCUI')
       D = L 'SEM ISTO, jogos com conta Xbox (Game Pass, Minecraft, Forza...) deixam de iniciar sessão.' 'WITHOUT THIS, games with an Xbox account (Game Pass, Minecraft, Forza...) cannot sign in.' 'SANS CELA, les jeux avec compte Xbox (Game Pass, Minecraft, Forza...) ne peuvent plus se connecter.' 'SIN ESTO, los juegos con cuenta Xbox (Game Pass, Minecraft, Forza...) no pueden iniciar sesión.' }
    @{ N = L 'Calculadora' 'Calculator' 'Calculatrice' 'Calculadora'; T = 4; P = @('Microsoft.WindowsCalculator')
       D = L 'Calculadora do Windows.' 'Windows calculator.' 'Calculatrice Windows.' 'Calculadora de Windows.' }
    @{ N = L 'Câmara' 'Camera' 'Caméra' 'Cámara'; T = 4; P = @('Microsoft.WindowsCamera')
       D = L 'App da câmara. As videochamadas usam a câmara diretamente.' 'Camera app. Video calls use the camera directly.' 'Application Caméra. Les appels vidéo utilisent directement la caméra.' 'App de la cámara. Las videollamadas usan la cámara directamente.' }
    @{ N = L 'Fotografias' 'Photos' 'Photos' 'Fotos'; T = 4; P = @('Microsoft.Windows.Photos')
       D = L 'Visualizador de imagens por defeito; depois abres imagens com o Paint ou outro programa.' 'Default image viewer; afterwards you open images with Paint or another program.' 'Visionneuse d''images par défaut ; ensuite vous ouvrez les images avec Paint ou un autre programme.' 'Visor de imágenes predeterminado; después abrirá las imágenes con Paint u otro programa.' }
    @{ N = L 'Leitor Multimédia (Media Player)' 'Media Player' 'Lecteur multimédia (Media Player)' 'Reproductor multimedia (Media Player)'; T = 4; P = @('Microsoft.ZuneMusic')
       D = L 'No Windows 11 é o leitor de música e vídeo por defeito.' 'In Windows 11 it is the default music and video player.' 'Dans Windows 11, c''est le lecteur de musique et de vidéo par défaut.' 'En Windows 11 es el reproductor de música y vídeo predeterminado.' }
    @{ N = L 'Alarmes e Relógio' 'Alarms & Clock' 'Alarmes et horloge' 'Alarmas y reloj'; T = 4; P = @('Microsoft.WindowsAlarms')
       D = L 'Alarmes, temporizador e relógios.' 'Alarms, timer and clocks.' 'Alarmes, minuteur et horloges.' 'Alarmas, temporizador y relojes.' }
    @{ N = L 'Notas Autoadesivas' 'Sticky Notes' 'Pense-bêtes' 'Notas rápidas'; T = 4; P = @('Microsoft.MicrosoftStickyNotes')
       D = L 'Notas no ambiente de trabalho.' 'Notes on the desktop.' 'Notes sur le bureau.' 'Notas en el escritorio.' }
    @{ N = L 'OneDrive' 'OneDrive' 'OneDrive' 'OneDrive'; T = 4; P = @(); OneDrive = $true
       D = L 'Sincronização na nuvem em segundo plano. Ficheiros só online deixam de abrir: descarrega-os antes.' 'Background cloud sync. Online-only files stop opening: download them first.' 'Synchronisation cloud en arrière-plan. Les fichiers en ligne uniquement ne s''ouvrent plus : téléchargez-les avant.' 'Sincronización en la nube en segundo plano. Los archivos solo en línea dejan de abrirse: descárguelos antes.' }
)
function EName($e) { $e.N[$script:Lang] }
function EDesc($e) { $e.D[$script:Lang] }
# Key used to match a catalog entry with the lines of the removal logs (same in every language)
function Get-EntryKey($e) { if ($e.OneDrive) { '' } else { $e.P -join ', ' } }

# Never removed, even if a catalog pattern matches
$Protected = '^(Microsoft\.(WindowsStore|StorePurchaseApp|DesktopAppInstaller|SecHealthUI|VCLibs.*|UI\.Xaml.*|NET\..*|Services\.Store\..*|' +
             'HEIFImageExtension|HEVCVideoExtension|VP9VideoExtensions|WebpImageExtension|WebMediaExtensions|RawImageExtension|AV1VideoExtension|' +
             'MPEG2VideoExtension|AVCEncoderVideoExtension|WindowsNotepad|Paint|WindowsTerminal|ScreenSketch|XboxGameCallableUI|' +
             'Windows\.(ShellExperienceHost|StartMenuExperienceHost|Search|CloudExperienceHost|SecHealthUI))|MicrosoftWindows\.Client\.(CBS|Core)|windows\.immersivecontrolpanel)$'


# -----------------------------------------------------------------------------
# Functions (no interface): analysis, removal, restore point
# -----------------------------------------------------------------------------
function Test-Admin {
    try { ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator) }
    catch { $false }
}

function ConvertTo-PsLiteral([string]$s) { $s -replace '([''\u2018\u2019\u201A\u201B])', '$1$1' }

# OneDrive uninstall command (per user or for everyone)
function Get-OneDriveUninstall {
    foreach ($k in 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall',
                   'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
                   'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall') {
        foreach ($sub in @(Get-ChildItem -LiteralPath $k -ErrorAction SilentlyContinue)) {
            $p = Get-ItemProperty -LiteralPath $sub.PSPath -ErrorAction SilentlyContinue
            if ($p.DisplayName -eq 'Microsoft OneDrive' -and $p.UninstallString) { return "$($p.UninstallString)" }
        }
    }
    $null
}

# Apps removed earlier with this tool, read from its logs: key -> date (yyyy-MM-dd).
# Old logs (removidas_*.txt, written by version 2.0.0) are read too.
function Get-RemovedLog {
    $map = @{}
    $dir = Join-Path $env:LOCALAPPDATA 'Debloat_GUI'
    if (-not (Test-Path -LiteralPath $dir)) { return $map }
    $files = @(Get-ChildItem -LiteralPath $dir -File -ErrorAction SilentlyContinue |
               Where-Object { $_.Name -like 'removidas_*.txt' -or $_.Name -like 'removed_*.txt' } | Sort-Object LastWriteTime)
    foreach ($f in $files) {
        try {
            foreach ($ln in [IO.File]::ReadAllLines($f.FullName, [Text.Encoding]::UTF8)) {
                # "  Name  [package1, package2]" (the "failed" lines have no brackets)
                if ($ln -match '^\s+\S.*\s\[(.*)\]\s*$') { $map[$Matches[1]] = $f.LastWriteTime.ToString('yyyy-MM-dd') }
            }
        } catch { }
    }
    $map
}

# One row per catalog entry, with its status on this PC:
#   present = installed (or provisioned) for some user, so it can be removed
#   removed = not installed, and found in this tool's removal logs
#   absent  = not installed (removed by something else, or never installed)
function Get-Rows {
    $installed = @(Get-AppxPackage -AllUsers -ErrorAction SilentlyContinue | Where-Object { -not $_.IsFramework -and -not $_.NonRemovable } | ForEach-Object { $_.Name })
    $prov      = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | ForEach-Object { $_.DisplayName })
    $names     = @($installed + $prov | Where-Object { $_ -and $_ -notmatch $Protected } | Select-Object -Unique)
    $log       = Get-RemovedLog
    foreach ($e in $Catalog) {
        $here = $false
        if ($e.OneDrive) { $here = [bool](Get-OneDriveUninstall) }
        else {
            foreach ($p in $e.P) {
                if (@($names | Where-Object { $_ -like $p }).Count) { $here = $true; break }
            }
        }
        $key = Get-EntryKey $e
        $state = if ($here) { 'present' } elseif ($log.ContainsKey($key)) { 'removed' } else { 'absent' }
        [pscustomobject]@{ Entry = $e; State = $state; Date = $log[$key] }
    }
}

function New-RestorePoint {
    try {
        $before = @(Get-ComputerRestorePoint -ErrorAction Stop).Count
        Checkpoint-Computer -Description (Tx 'rpName') -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop -WarningAction SilentlyContinue
        @(Get-ComputerRestorePoint -ErrorAction Stop).Count -gt $before
    } catch { $false }
}

# Removes one catalog entry; returns $true if nothing of it is left
function Remove-Entry($e, [scriptblock]$log, $prov) {
    if ($e.OneDrive) {
        $u = Get-OneDriveUninstall
        if (-not $u) { return $true }
        Get-Process -Name OneDrive -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        $cmdExe = if ($env:ComSpec) { $env:ComSpec } else { 'cmd.exe' }
        Start-Process -FilePath $cmdExe -ArgumentList ('/c "{0}"' -f $u) -Wait -WindowStyle Hidden
        return -not (Get-OneDriveUninstall)
    }
    $ok = $true
    foreach ($p in $e.P) {
        foreach ($pkg in @(Get-AppxPackage -AllUsers -Name $p -ErrorAction SilentlyContinue)) {
            if ($pkg.Name -match $Protected -or $pkg.NonRemovable -or $pkg.IsFramework) { continue }
            try {
                Remove-AppxPackage -Package $pkg.PackageFullName -AllUsers -ErrorAction Stop
            } catch {
                try { Remove-AppxPackage -Package $pkg.PackageFullName -ErrorAction Stop }   # this user only
                catch { & $log (Tx 'failedLog' $pkg.Name $_.Exception.Message); $ok = $false }
            }
        }
        # It also stops being installed for new accounts
        foreach ($pp in @($prov | Where-Object { $_.DisplayName -like $p -and $_.DisplayName -notmatch $Protected })) {
            try { [void](Remove-AppxProvisionedPackage -Online -PackageName $pp.PackageName -ErrorAction Stop) }
            catch { & $log (Tx 'failedProv' $pp.DisplayName $_.Exception.Message); $ok = $false }
        }
    }
    $ok
}

# Removes a list of entries, with a log; returns @(removed, failed)
function Invoke-RemoveEntries($entries, [scriptblock]$log) {
    $prov = @(Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue)
    $done = @(); $failed = @()
    foreach ($e in $entries) {
        & $log (Tx 'removing' (EName $e))
        if (Remove-Entry $e $log $prov) { $done += $e } else { $failed += $e }
    }
    , @($done, $failed)
}

# ===== GUI =====
try {
    # --- Administrator: reopens elevated, without a console, and this copy ends ---
    if (-not (Test-Admin)) {
        $exe = Join-Path $PSHOME 'powershell.exe'
        if (-not (Test-Path -LiteralPath $exe)) { $exe = 'powershell' }
        $cmd = "`$env:DEBLOATGUI_SCRIPT = '{0}'; iex ([IO.File]::ReadAllText(`$env:DEBLOATGUI_SCRIPT, [Text.Encoding]::UTF8))" -f (ConvertTo-PsLiteral $env:DEBLOATGUI_SCRIPT)
        $enc = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($cmd))
        try {
            Start-Process -FilePath $exe -Verb RunAs -WindowStyle Hidden -ErrorAction Stop -ArgumentList "-NoProfile -ExecutionPolicy Bypass -STA -EncodedCommand $enc"
            exit 0
        } catch {
            Write-Host (Tx 'noAdmin') -ForegroundColor Yellow
            exit 1
        }
    }

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    # Hides the console behind the window (when already opened as administrator)
    try {
        Add-Type -Namespace DebloatGui -Name Con -MemberDefinition '[DllImport("kernel32.dll")] public static extern IntPtr GetConsoleWindow(); [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int n);'
        [void][DebloatGui.Con]::ShowWindow([DebloatGui.Con]::GetConsoleWindow(), 0)
    } catch { }

    function Rgb($a) { [System.Drawing.Color]::FromArgb($a[0], $a[1], $a[2]) }
    $cBg    = Rgb @(28, 30, 36);   $cPage = Rgb @(36, 38, 46); $cBox = Rgb @(20, 22, 27)
    $cText  = Rgb @(235, 236, 240); $cMuted = Rgb @(130, 136, 150)
    $cGreen = Rgb @(72, 199, 116);  $cBlue = Rgb @(96, 165, 250)
    $fText  = New-Object System.Drawing.Font('Segoe UI', 9)
    $fBold  = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
    $fTitle = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $fMono  = New-Object System.Drawing.Font('Consolas', 9)

    function New-Ctl($type, $x, $y, $w, $h) {
        $c = New-Object ("System.Windows.Forms.$type")
        $c.Location = New-Object System.Drawing.Point($x, $y)
        $c.Size = New-Object System.Drawing.Size($w, $h)
        $c
    }
    function New-Btn($text, $x, $y, $w, $h, $color) {
        $b = New-Ctl 'Button' $x $y $w $h
        $b.Text = $text; $b.FlatStyle = 'Flat'; $b.BackColor = $color; $b.ForeColor = [System.Drawing.Color]::White
        $b.Font = $fBold; $b.FlatAppearance.BorderSize = 0; $b.Cursor = [System.Windows.Forms.Cursors]::Hand
        $b
    }
    function New-List($x, $y, $w, $h, [bool]$checks) {
        $lv = New-Ctl 'ListView' $x $y $w $h
        $lv.View = 'Details'; $lv.FullRowSelect = $true; $lv.CheckBoxes = $checks; $lv.HideSelection = $true
        $lv.BackColor = $cBox; $lv.ForeColor = $cText; $lv.Font = $fText; $lv.HeaderStyle = 'Nonclickable'
        [void]$lv.Columns.Add('App', 245); [void]$lv.Columns.Add('Level', 80); [void]$lv.Columns.Add('Status', 160); [void]$lv.Columns.Add('What', 335)
        $lv
    }
    function New-Combo($x, $y, $w) {
        $c = New-Ctl 'ComboBox' $x $y $w 24
        $c.DropDownStyle = 'DropDownList'; $c.BackColor = $cBox; $c.ForeColor = $cText; $c.FlatStyle = 'Flat'
        $c
    }
    function Add-ListRow($lv, $row) {
        $e = $row.Entry
        $gone = $row.State -ne 'present'
        $it = New-Object System.Windows.Forms.ListViewItem((EName $e))
        $it.UseItemStyleForSubItems = $false
        $it.ForeColor = $(if ($gone) { $cMuted } else { $cText })
        $s1 = $it.SubItems.Add((TierName $e.T)); $s1.ForeColor = $(if ($gone) { $cMuted } else { Rgb $Tiers[$e.T].Rgb })
        switch ($row.State) {
            'present' { $s2 = $it.SubItems.Add((Tx 'stPresent')); $s2.ForeColor = $cGreen }
            'removed' { $s2 = $it.SubItems.Add((Tx 'stRemoved' $row.Date)); $s2.ForeColor = $cBlue }
            default   { $s2 = $it.SubItems.Add((Tx 'stAbsent')); $s2.ForeColor = $cMuted }
        }
        $s3 = $it.SubItems.Add((EDesc $e)); $s3.ForeColor = $(if ($gone) { $cMuted } else { $cText })
        $it.Tag = $row
        [void]$lv.Items.Add($it)
    }
    # Fills a list: filter 0 = all, 1 = can be removed, 2 = already removed or not installed.
    # Rows that can be removed come first, then removed, then not installed (catalog order inside each).
    function Fill-List($lv, $rows, [int]$filter) {
        $lv.BeginUpdate(); $lv.Items.Clear()
        foreach ($st in 'present', 'removed', 'absent') {
            if ($filter -eq 1 -and $st -ne 'present') { continue }
            if ($filter -eq 2 -and $st -eq 'present') { continue }
            foreach ($r in $rows) { if ($r.State -eq $st) { Add-ListRow $lv $r } }
        }
        $lv.EndUpdate()
    }
    function Get-Counts($rows) {
        @(@($rows | Where-Object { $_.State -eq 'present' }).Count,
          @($rows | Where-Object { $_.State -eq 'removed' }).Count,
          @($rows | Where-Object { $_.State -eq 'absent' }).Count)
    }

    # --- Window ---
    $form = New-Object System.Windows.Forms.Form
    $form.ClientSize = New-Object System.Drawing.Size(900, 680)
    $form.StartPosition = 'CenterScreen'; $form.FormBorderStyle = 'FixedSingle'; $form.MaximizeBox = $false
    $form.BackColor = $cBg; $form.ForeColor = $cText; $form.Font = $fText

    $tabs = New-Ctl 'TabControl' 12 12 876 470
    $tabModes  = New-Object System.Windows.Forms.TabPage; $tabModes.BackColor  = $cPage
    $tabCustom = New-Object System.Windows.Forms.TabPage; $tabCustom.BackColor = $cPage
    $tabs.TabPages.Add($tabModes); $tabs.TabPages.Add($tabCustom)
    $form.Controls.Add($tabs)

    # Language selector (on the empty part of the tab strip, added after the tabs so it is on top)
    $cmbLang = New-Combo 738 12 150
    foreach ($n in $LangNames) { [void]$cmbLang.Items.Add($n) }
    $cmbLang.SelectedIndex = [array]::IndexOf($Langs, $script:Lang)
    $form.Controls.Add($cmbLang)
    $cmbLang.BringToFront()

    $txtLog = New-Ctl 'TextBox' 12 490 876 150
    $txtLog.Multiline = $true; $txtLog.ReadOnly = $true; $txtLog.ScrollBars = 'Vertical'
    $txtLog.BackColor = $cBox; $txtLog.ForeColor = Rgb @(210, 210, 210); $txtLog.Font = $fMono
    $form.Controls.Add($txtLog)
    $lblStatus = New-Ctl 'Label' 12 648 876 24
    $lblStatus.ForeColor = $cMuted
    $form.Controls.Add($lblStatus)

    $script:Log = {
        param($t)
        $txtLog.AppendText($t + "`r`n")
        [System.Windows.Forms.Application]::DoEvents()
    }

    # --- Modes tab ---
    $modeButtons = @{}
    foreach ($t in 1..4) {
        $b = New-Btn '' (12 + ($t - 1) * 211) 12 203 64 (Rgb $Tiers[$t].Rgb)
        $b.Tag = $t
        $b.Add_Click({ Show-Mode $this.Tag })
        $tabModes.Controls.Add($b)
        $modeButtons[$t] = $b
    }
    $lblModeTitle = New-Ctl 'Label' 12 86 540 26;  $lblModeTitle.Font = $fTitle
    $lblFilter1   = New-Ctl 'Label' 560 91 62 20;  $lblFilter1.ForeColor = $cMuted
    $cmbFilter1   = New-Combo 624 87 232
    $lblModeDesc  = New-Ctl 'Label' 12 114 844 58; $lblModeDesc.ForeColor = $cMuted
    $lvMode = New-List 12 176 844 190 $false
    $lblSum1 = New-Ctl 'Label' 12 370 844 20; $lblSum1.ForeColor = $cMuted
    $chkRestore1 = New-Ctl 'CheckBox' 12 398 360 24
    $chkRestore1.Checked = $true; $chkRestore1.ForeColor = $cText
    $btnRemoveMode = New-Btn '' 556 392 300 44 (Rgb @(220, 53, 69))
    $tabModes.Controls.AddRange(@($lblModeTitle, $lblFilter1, $cmbFilter1, $lblModeDesc, $lvMode, $lblSum1, $chkRestore1, $btnRemoveMode))

    # --- Custom tab ---
    $lblCustom = New-Ctl 'Label' 12 4 844 32
    $lblCustom.ForeColor = $cMuted
    $tabCustom.Controls.Add($lblCustom)
    $upButtons = @{}
    foreach ($t in 1..4) {
        $b = New-Btn '' (12 + ($t - 1) * 150) 40 142 30 (Rgb $Tiers[$t].Rgb)
        $b.Tag = $t
        $b.Add_Click({
            $max = $this.Tag
            foreach ($it in $lvCustom.Items) { $it.Checked = ($it.Tag.State -eq 'present' -and $it.Tag.Entry.T -le $max) }
        })
        $tabCustom.Controls.Add($b)
        $upButtons[$t] = $b
    }
    $btnNone = New-Btn '' 622 40 130 30 (Rgb @(70, 75, 88))
    $btnNone.Add_Click({ foreach ($it in $lvCustom.Items) { $it.Checked = $false } })
    $lblFilter2 = New-Ctl 'Label' 12 80 62 20; $lblFilter2.ForeColor = $cMuted
    $cmbFilter2 = New-Combo 76 76 300
    $tabCustom.Controls.AddRange(@($btnNone, $lblFilter2, $cmbFilter2))
    $lvCustom = New-List 12 106 844 266 $true
    # Rows that are not installed cannot be ticked
    $lvCustom.Add_ItemCheck({ param($s, $e) if ($s.Items[$e.Index].Tag.State -ne 'present') { $e.NewValue = $e.CurrentValue } })
    $lvCustom.Add_ItemChecked({ Update-CustomButton })
    $lblSum2 = New-Ctl 'Label' 12 374 844 20; $lblSum2.ForeColor = $cMuted
    $chkRestore2 = New-Ctl 'CheckBox' 12 398 360 24
    $chkRestore2.Checked = $true; $chkRestore2.ForeColor = $cText
    $chkRestore1.Add_CheckedChanged({ $chkRestore2.Checked = $chkRestore1.Checked })
    $chkRestore2.Add_CheckedChanged({ $chkRestore1.Checked = $chkRestore2.Checked })
    $btnRemoveCustom = New-Btn '' 556 392 300 44 (Rgb @(220, 53, 69))
    $tabCustom.Controls.AddRange(@($lvCustom, $lblSum2, $chkRestore2, $btnRemoveCustom))

    # --- State and interface refresh ---
    $script:Rows = @()
    $script:Mode = 3
    $script:Filter = 0
    $script:Busy = $false

    function Get-ModeRows([int]$t) { @($script:Rows | Where-Object { $_.Entry.T -le $t }) }
    function Get-ModeEntries([int]$t) { @(Get-ModeRows $t | Where-Object { $_.State -eq 'present' } | ForEach-Object { $_.Entry }) }

    function Show-Mode([int]$t) {
        $script:Mode = $t
        foreach ($k in 1..4) {
            $modeButtons[$k].FlatAppearance.BorderSize = $(if ($k -eq $t) { 3 } else { 0 })
            $modeButtons[$k].FlatAppearance.BorderColor = [System.Drawing.Color]::White
        }
        $lblModeTitle.Text = '{0}. {1}  -  {2}' -f $t, (TierName $t), (TierTag $t)
        $lblModeTitle.ForeColor = Rgb $Tiers[$t].Rgb
        $lblModeDesc.Text = TierDesc $t
        $rows = Get-ModeRows $t
        Fill-List $lvMode $rows $script:Filter
        $c = Get-Counts $rows
        $lblSum1.Text = Tx 'summary' $c[0] $c[1] $c[2]
        $btnRemoveMode.Text = Tx 'btnMode' $c[0] (TierName $t)
        $btnRemoveMode.BackColor = Rgb $Tiers[$t].Rgb
        $btnRemoveMode.Enabled = $c[0] -gt 0
    }

    function Update-ModeButtons {
        foreach ($t in 1..4) {
            $n = (Get-ModeEntries $t).Count
            $star = if ($t -eq 3) { Tx 'star' } else { '' }
            $modeButtons[$t].Text = ('{0}. {1}{2}' -f $t, (TierName $t), $star) + "`r`n" + (Tx 'modeLine2' $n)
        }
    }

    function Update-CustomButton {
        $n = @($lvCustom.CheckedItems).Count
        $btnRemoveCustom.Text = Tx 'btnCustom' $n
        $btnRemoveCustom.Enabled = $n -gt 0
    }

    # Refills both lists and every count (the ticks of the Custom tab are kept)
    function Refresh-View {
        $keep = @($lvCustom.CheckedItems | ForEach-Object { $_.Tag.Entry })
        Update-ModeButtons
        Show-Mode $script:Mode
        Fill-List $lvCustom $script:Rows $script:Filter
        foreach ($it in $lvCustom.Items) { if ($it.Tag.State -eq 'present' -and ($keep -contains $it.Tag.Entry)) { $it.Checked = $true } }
        $c = Get-Counts $script:Rows
        $lblSum2.Text = Tx 'summary' $c[0] $c[1] $c[2]
        Update-CustomButton
    }

    # Sets every text of the window in the chosen language
    function Apply-Language {
        $script:Busy = $true
        $form.Text = Tx 'title' $AppVersion
        $tabModes.Text = Tx 'tabModes'; $tabCustom.Text = Tx 'tabCustom'
        foreach ($lv in $lvMode, $lvCustom) {
            $lv.Columns[0].Text = Tx 'colApp'; $lv.Columns[1].Text = Tx 'colLevel'
            $lv.Columns[2].Text = Tx 'colStatus'; $lv.Columns[3].Text = Tx 'colWhat'
        }
        $lblFilter1.Text = Tx 'filterLbl'; $lblFilter2.Text = Tx 'filterLbl'
        foreach ($cb in $cmbFilter1, $cmbFilter2) {
            $cb.Items.Clear()
            [void]$cb.Items.Add((Tx 'fAll')); [void]$cb.Items.Add((Tx 'fRemovable')); [void]$cb.Items.Add((Tx 'fGone'))
            $cb.SelectedIndex = $script:Filter
        }
        $chkRestore1.Text = Tx 'restore'; $chkRestore2.Text = Tx 'restore'
        $lblCustom.Text = Tx 'customHint'
        foreach ($t in 1..4) { $upButtons[$t].Text = Tx 'upTo' (TierName $t) }
        $btnNone.Text = Tx 'untick'
        $script:Busy = $false
        Refresh-View
        if ($script:Rows.Count) {
            $c = Get-Counts $script:Rows
            $lblStatus.Text = Tx 'found' $c[0] ($c[1] + $c[2]) $script:Rows.Count
        }
    }

    function Update-All {
        $lblStatus.Text = Tx 'analyzing'
        $tabs.Enabled = $false; $form.UseWaitCursor = $true
        [System.Windows.Forms.Application]::DoEvents()
        $script:Rows = @(Get-Rows)
        Refresh-View
        $tabs.Enabled = $true; $form.UseWaitCursor = $false
        $c = Get-Counts $script:Rows
        $lblStatus.Text = Tx 'found' $c[0] ($c[1] + $c[2]) $script:Rows.Count
    }

    $cmbLang.Add_SelectedIndexChanged({
        if ($script:Busy -or $cmbLang.SelectedIndex -lt 0) { return }
        $script:Lang = $Langs[$cmbLang.SelectedIndex]
        try {
            [void](New-Item -ItemType Directory -Path (Split-Path -Parent $LangFile) -Force)
            [IO.File]::WriteAllText($LangFile, $script:Lang)
        } catch { }
        Apply-Language
    })
    $onFilter = {
        if ($script:Busy) { return }
        $script:Filter = $this.SelectedIndex
        $script:Busy = $true
        foreach ($cb in $cmbFilter1, $cmbFilter2) { if ($cb.SelectedIndex -ne $script:Filter) { $cb.SelectedIndex = $script:Filter } }
        $script:Busy = $false
        Refresh-View
    }
    $cmbFilter1.Add_SelectedIndexChanged($onFilter)
    $cmbFilter2.Add_SelectedIndexChanged($onFilter)

    # --- Removal (with confirmation, restore point and log) ---
    function Start-Removal($entries, [string]$title, [bool]$restore) {
        $entries = @($entries)
        if (-not $entries) { [void][System.Windows.Forms.MessageBox]::Show((Tx 'nothing'), 'Debloat', 'OK', 'Information'); return }
        $list = ($entries | ForEach-Object { '  - ' + (EName $_) }) -join "`r`n"
        $warn = ''
        if (@($entries | Where-Object { $_.P -contains 'Microsoft.XboxIdentityProvider' }).Count) {
            $warn = "`r`n`r`n" + (Tx 'xboxWarn')
        }
        $q = (Tx 'confirmHead' $title) + "`r`n`r`n" + $list + $warn + "`r`n`r`n" + (Tx 'confirmAsk')
        if ([System.Windows.Forms.MessageBox]::Show($q, (Tx 'confirmTitle'), 'YesNo', 'Warning') -ne 'Yes') { & $script:Log (Tx 'cancelled'); return }

        $tabs.Enabled = $false; $form.UseWaitCursor = $true
        & $script:Log ''
        & $script:Log ('>>> {0} <<<' -f $title)
        if ($restore) {
            & $script:Log (Tx 'restoring')
            if (New-RestorePoint) {
                & $script:Log (Tx 'restoreOk' (Tx 'rpName'))
            } else {
                & $script:Log (Tx 'restoreFail')
                $a = [System.Windows.Forms.MessageBox]::Show((Tx 'restoreAsk'), (Tx 'restoreTitle'), 'YesNo', 'Warning')
                if ($a -ne 'Yes') { & $script:Log (Tx 'cancelled'); $tabs.Enabled = $true; $form.UseWaitCursor = $false; return }
            }
        }
        $r = Invoke-RemoveEntries $entries $script:Log
        $done = @($r[0]); $failed = @($r[1])

        # Log of the removed apps, to reinstall them if needed (also used to show "Removed" in the lists).
        # The "[packages]" at the end of each line is what the lists use to recognize the app, in any language.
        try {
            $dir = Join-Path $env:LOCALAPPDATA 'Debloat_GUI'
            [void](New-Item -ItemType Directory -Path $dir -Force)
            $f = Join-Path $dir ('removed_{0}.txt' -f (Get-Date -Format 'yyyyMMdd_HHmmss'))
            $lines = @((Tx 'logHeader' $title (Get-Date -Format 'yyyy-MM-dd HH:mm')), '', (Tx 'logRemoved')) +
                     @($done | ForEach-Object { '  ' + (EName $_) + '  [' + (Get-EntryKey $_) + ']' })
            if ($failed) { $lines += @('', (Tx 'logFailed')) + @($failed | ForEach-Object { '  ' + (EName $_) }) }
            [IO.File]::WriteAllLines($f, [string[]]$lines, (New-Object System.Text.UTF8Encoding $true))
            & $script:Log (Tx 'logPath' $f)
        } catch { }

        & $script:Log (Tx 'done' $done.Count $failed.Count)
        $form.UseWaitCursor = $false
        Update-All
        [void][System.Windows.Forms.MessageBox]::Show(((Tx 'doneBox' $done.Count $failed.Count) + "`r`n`r`n" + (Tx 'restartMsg')), (Tx 'doneTitle'), 'OK', 'Information')
    }

    # An error inside a button is shown and the window becomes usable again
    function Show-Error($err) {
        $tabs.Enabled = $true; $form.UseWaitCursor = $false
        & $script:Log (Tx 'errLog' $err.Exception.Message)
        [void][System.Windows.Forms.MessageBox]::Show((Tx 'errBox' $err.Exception.Message), 'Debloat GUI', 'OK', 'Error')
    }

    $btnRemoveMode.Add_Click({ try { Start-Removal (Get-ModeEntries $script:Mode) (Tx 'modeName' (TierName $script:Mode)) $chkRestore1.Checked } catch { Show-Error $_ } })
    $btnRemoveCustom.Add_Click({ try { Start-Removal @($lvCustom.CheckedItems | ForEach-Object { $_.Tag.Entry }) (Tx 'customName') $chkRestore2.Checked } catch { Show-Error $_ } })

    # --- First texts ---
    Apply-Language
    $txtLog.Text = (@(
        (Tx 'title' $AppVersion),
        (Tx 'intro1'),
        (Tx 'intro2'),
        (Tx 'intro3'),
        ''
    ) -join "`r`n")

    $form.Add_Shown({ try { $form.Activate(); Update-All } catch { Show-Error $_ } })
    [void]$form.ShowDialog()
    exit 0
} catch {
    $msg = Tx 'unexpected' $_.Exception.Message "`r`n" $_.InvocationInfo.ScriptLineNumber ("$($_.InvocationInfo.Line)".Trim())
    try { Add-Type -AssemblyName System.Windows.Forms; [void][System.Windows.Forms.MessageBox]::Show($msg, 'Debloat GUI', 'OK', 'Error') } catch { Write-Host $msg -ForegroundColor Red }
    exit 1
}
