# Record the terminal with VHS
# https://github.com/charmbracelet/vhs

Output examples/presentation.gif
Output examples/presentation.webm

Require echo
Require nvim

Set Shell "bash"
Set FontSize 22
Set Width 1200
Set Height 600

Type "echo 'Welcome to presenting.nvim!'" Sleep 500ms Enter
Sleep 1s

Type "nvim -c Presenting README.md" Sleep 900ms Enter
Sleep 4s

Type "n" Sleep 4s
Type "n" Sleep 4s
Type "n" Sleep 3s
Type "n" Sleep 3s
Type "n" Sleep 3s
Type "n" Sleep 3s
Type "n" Sleep 3s
Type "n" Sleep 3s
Type "n" Sleep 3s
Type "n" Sleep 3s

Type "q"
Sleep 500ms

Type "echo 'This works for other file types as well!'" Sleep 500ms Enter

Type "nvim -c Presenting README.adoc" Sleep 900ms Enter
Sleep 1s
Type "q"

Type "nvim -c Presenting README.org" Sleep 900ms Enter
Sleep 1s
